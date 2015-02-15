class ConclusionReview < ActiveRecord::Base
  include ParameterSelector

  has_paper_trail meta: {
    organization_id: ->(model) { Organization.current_id }
  }

  # Constantes
  GENERIC_COLUMNS_FOR_SEARCH = {
    :issue_date => {
      :column => "#{quoted_table_name}.#{qcn('issue_date')}",
      :operator => SEARCH_ALLOWED_OPERATORS.values, :mask => "%s",
      :conversion_method => lambda { |value|
        Timeliness.parse(value, :date).to_s(:db)
      },
      :regexp => SEARCH_DATE_REGEXP
    },
    :period => {
      :column => "#{Period.quoted_table_name}.#{Period.qcn('number')}", :operator => '=', :mask => "%d",
      :conversion_method => :to_i, :regexp => /\A\s*\d+\s*\Z/
    },
    :identification => {
      :column => "LOWER(#{Review.quoted_table_name}.#{Review.qcn('identification')})",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    },
    :business_unit => {
      :column => "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('name')})", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :project => {
      :column => "LOWER(#{PlanItem.quoted_table_name}.#{PlanItem.qcn('project')})", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  }.with_indifferent_access

  # Named scopes
  scope :list, -> { where(organization_id: Organization.current_id) }
  scope :for_period, ->(period) {
    includes(:review =>:period).where(
      :periods => { :id => period.id }
    ).references(:periods)
  }
  scope :by_business_unit_type, ->(business_unit_type_id) {
    includes(:review => { :plan_item => :business_unit }).where(
      :business_units => { :business_unit_type_id => business_unit_type_id }
    ).references(:business_units)
  }
  scope :by_business_unit_names, ->(*business_unit_names) {
    conditions = []
    parameters = {}

    business_unit_names.each_with_index do |business_unit_name, i|
      conditions << "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn('name')}) LIKE :bu_#{i}"
      parameters[:"bu_#{i}"] = "%#{business_unit_name.mb_chars.downcase}%"
    end

    includes(:plan_item => :business_unit).where(
      conditions.join(' OR '), parameters
    ).references(:bussiness_unit_types)
  }
  scope :by_control_objective_names, ->(*control_objective_names) {
    conditions = []
    parameters = {}

    control_objective_names.each_with_index do |control_objective_name, i|
      conditions << "LOWER(#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn('name')}) LIKE :co_#{i}"
      parameters[:"co_#{i}"] = "%#{control_objective_name.mb_chars.downcase}%"
    end

    includes(:review => {:control_objective_items => :control_objective}).where(
      conditions.join(' OR '), parameters
    ).references(:control_objectives)
  }
  scope :notorious, ->(final) {
     includes(:review => {
         :control_objective_items => (final ? :final_weaknesses : :weaknesses)}
     ).where(
       "#{Weakness.quoted_table_name}.#{Weakness.qcn('risk')} = #{Weakness.quoted_table_name}.#{Weakness.qcn('highest_risk')}"
    ).references(:findings)
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Restricciones de los atributos
  attr_readonly :review_id

  # Restricciones
  validates :review_id, :organization_id, :presence => true
  validates :issue_date, :applied_procedures, :presence => true
  validates_length_of :type, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_date :issue_date, :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :review
  belongs_to :organization
  has_one :plan_item, :through => :review
  has_many :control_objective_items, :through => :review

  def self.columns_for_sort
    HashWithIndifferentAccess.new({
      :issue_date => {
        :name => ConclusionReview.human_attribute_name(:issue_date),
        :field => "#{ConclusionReview.quoted_table_name}.#{ConclusionReview.qcn('issue_date')} ASC"
      },
      :period => {
        :name => Period.model_name.human,
        :field => "#{Period.quoted_table_name}.#{Period.qcn('number')} ASC"
      },
      :identification => {
        :name => Review.human_attribute_name(:identification),
        :field => "#{Review.quoted_table_name}.#{Review.qcn('identification')} ASC"
      }
    })
  end

  def can_be_destroyed?
    false
  end

  def has_final_review?
    self.review.try(:has_final_review?)
  end

  def findings
    self.kind_of?(ConclusionFinalReview) ?
      (self.review.final_weaknesses + self.review.final_oportunities) :
      (self.review.weaknesses + self.review.oportunities)
  end

  def send_by_email_to(user, options = {})
    NotifierMailer.delay.conclusion_review_notification(
      user, self,
      options.merge(organization_id: Organization.current_id, user_id: PaperTrail.whodunnit)
    )
  end

  def to_pdf(organization = nil, *args)
    options = args.extract_options!
    pdf = Prawn::Document.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) || self.has_final_review?
    cover_text = "\n\n\n\n#{Review.model_name.human.upcase}\n\n"
    cover_text << "#{self.review.identification}\n\n"
    cover_text << "#{self.review.plan_item.project}\n\n\n\n\n\n"
    cover_bottom_text = "#{self.review.plan_item.business_unit.name}\n"
    cover_bottom_text << I18n.l(self.issue_date, :format => :long)

    current_organization = Organization.find(self.organization_id)

    pdf.add_review_header organization, self.review.identification.strip,
      self.review.plan_item.project.strip

    if self.instance_of?(ConclusionDraftReview)
      pdf.add_watermark(self.class.model_name.human)
    end

    pdf.add_title cover_text, (PDF_FONT_SIZE * 1.5).round, :center, false
    pdf.add_title cover_bottom_text, (PDF_FONT_SIZE * 1.25).round, :center,
      false

    pdf.start_new_page
    pdf.add_page_footer

    pdf.add_title self.review.description

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(I18n.t('conclusion_review.issue_date_title'),
      I18n.l(self.issue_date, :format => :long))
    pdf.add_description_item(
      self.review.business_unit.business_unit_type.business_unit_label,
      self.review.business_unit.name)

    unless self.review.business_unit.business_unit_type.project_label.blank?
      pdf.add_description_item(
        self.review.business_unit.business_unit_type.project_label,
        self.review.plan_item.project)
    end

    pdf.add_description_item(
      I18n.t('conclusion_review.audit_period_title'),
      I18n.t('conclusion_review.audit_period',
        :start => I18n.l(self.review.plan_item.start, :format => :long),
        :end => I18n.l(self.review.plan_item.end, :format => :long)
      )
    )

    pdf.add_subtitle I18n.t('conclusion_review.objectives_and_scopes'),
      PDF_FONT_SIZE, PDF_FONT_SIZE

    grouped_control_objectives = self.review.grouped_control_objective_items(
      :hide_excluded_from_score => options[:hide_control_objectives_excluded_from_score] == '1'
    )

    grouped_control_objectives.each do |process_control, cois|
      process_control_text = "<b>#{ProcessControl.model_name.human}: " +
          "<i>#{process_control.name}</i></b>"
      process_control_text += " (#{process_control.best_practice.name})" if current_organization.kind.eql?('public')
      pdf.text process_control_text, :align => :justify,
          :inline_format => true

      coi_columns = []

      cois.sort.each do |coi|
        coi_columns << ['•', coi.to_s]
      end

      if coi_columns.present?
        pdf.indent(PDF_FONT_SIZE) do
          pdf.table coi_columns, :cell_style => {
            :align => :justify, :border_width => 0, :padding => [0, 0, 5, 0]
          }
        end
      end
    end

    unless self.applied_procedures.blank?
      pdf.add_subtitle I18n.t('conclusion_review.applied_procedures'),
        PDF_FONT_SIZE
      pdf.text self.applied_procedures, :align => :justify
    end

    pdf.add_subtitle I18n.t('conclusion_review.conclusion'), PDF_FONT_SIZE

    unless options[:hide_score]
      pdf.move_down PDF_FONT_SIZE
      self.review.add_score_details_table(pdf)

      pdf.move_down((PDF_FONT_SIZE * 0.75).round)

      pdf.font_size((PDF_FONT_SIZE * 0.6).round) do
        pdf.text "<i>#{I18n.t('review.review_qualification_explanation')}</i>",
          :align => :justify, :inline_format => true
      end
    end

    unless self.conclusion.blank?
      pdf.move_down PDF_FONT_SIZE
      pdf.text self.conclusion, :align => :justify,
        :font_size => PDF_FONT_SIZE
    end

    review_has_fortresses = grouped_control_objectives.any? do |_, cois|
      cois.any? do |coi|
        !(use_finals ? coi.final_fortresses : coi.fortresses).blank?
      end
    end

    if review_has_fortresses
      pdf.add_subtitle(
        I18n.t('conclusion_review.fortresses'), PDF_FONT_SIZE, PDF_FONT_SIZE)

      grouped_control_objectives.each do |process_control, cois|
        has_fortresses = cois.any? do |coi|
          !(use_finals ? coi.final_fortresses : coi.fortresses).blank?
        end

        if has_fortresses
          pc_id = process_control.id.to_s
          column_headers, column_widths = [], []

          column_headers << "<b><i>#{ProcessControl.model_name.human}: " +
              "#{process_control.name}</i></b>"
          column_widths << pdf.percent_width(100)

          cois.each do |coi|
            fortresses = (
              use_finals ? coi.final_fortresses : coi.fortresses
            ).order(review_code: :asc)

            fortresses.each do |f|
              column_data = []
              f_data = coi.pdf_data(f)

              if f_data[:column].present?
                column_data << column_headers
                column_data << f_data[:column]

                pdf.move_down PDF_FONT_SIZE

                pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                  table_options = pdf.default_table_options(column_widths)

                  pdf.table(column_data, table_options) do
                    row(0).style(
                      :background_color => 'cccccc',
                      :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                    )
                  end
                end
              end

              pdf.move_down PDF_FONT_SIZE
              pdf.text f_data[:text], :align => :justify, :inline_format => true
            end
          end
        end
      end
    end

    review_has_nonconformities = grouped_control_objectives.any? do |_, cois|
      cois.any? do |coi|
        !(use_finals ? coi.final_nonconformities : coi.nonconformities).not_revoked.blank?
      end
    end

    if review_has_nonconformities
      pdf.add_subtitle(
        I18n.t('conclusion_review.nonconformities'), PDF_FONT_SIZE, PDF_FONT_SIZE)

      grouped_control_objectives.each do |process_control, cois|
        has_nonconformities = cois.any? do |coi|
          !(use_finals ? coi.final_nonconformities : coi.nonconformities).not_revoked.blank?
        end

        if has_nonconformities
          pc_id = process_control.id.to_s
          column_headers, column_widths = [], []

          column_headers << "<b><i>#{ProcessControl.model_name.human}: " +
              "#{process_control.name}</i></b>"
          column_widths << pdf.percent_width(100)

          cois.each do |coi|
            nonconformities = (
              use_finals ? coi.final_nonconformities : coi.nonconformities
            ).not_revoked.order(review_code: :asc)

            nonconformities.each do |nc|
              column_data = []
              nc_data = coi.pdf_data(nc)

              if nc_data[:column].present?
                column_data << column_headers
                column_data << nc_data[:column]

                pdf.move_down PDF_FONT_SIZE

                pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                  table_options = pdf.default_table_options(column_widths)

                  pdf.table(column_data, table_options) do
                    row(0).style(
                      :background_color => 'cccccc',
                      :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                    )
                  end
                end
              end

              pdf.move_down PDF_FONT_SIZE
              pdf.text nc_data[:text], :align => :justify, :inline_format => true
            end
          end
        end
      end
    end

    review_has_observations = grouped_control_objectives.any? do |_, cois|
      cois.any? do |coi|
        !(use_finals ? coi.final_weaknesses : coi.weaknesses).not_revoked.blank?
      end
    end

    if review_has_observations
      pdf.add_subtitle(
        I18n.t('conclusion_review.findings'), PDF_FONT_SIZE, PDF_FONT_SIZE)

      grouped_control_objectives.each do |process_control, cois|
        has_observations = cois.any? do |coi|
          !(use_finals ? coi.final_weaknesses : coi.weaknesses).not_revoked.blank?
        end

        if has_observations
          pc_id = process_control.id.to_s
          column_headers, column_widths = [], []
          header = "<b><i>#{ProcessControl.model_name.human}: #{process_control.name}</i></b>"
          header += " (#{process_control.best_practice.name})" if current_organization.kind.eql?('public')
          column_headers << header
          column_widths << pdf.percent_width(100)

          cois.each do |coi|
            weaknesses = (
              use_finals ? coi.final_weaknesses : coi.weaknesses
            ).not_revoked.order(review_code: :asc)

            weaknesses.each do |w|
              column_data = []
              w_data = coi.pdf_data(w)

              unless w_data[:column].blank?
                column_data << column_headers
                column_data << w_data[:column]

                pdf.move_down PDF_FONT_SIZE

                pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                  table_options = pdf.default_table_options(column_widths)

                  pdf.table(column_data, table_options) do
                    row(0).style(
                      :background_color => 'cccccc',
                      :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                    )
                  end
                end
              end

              pdf.move_down PDF_FONT_SIZE
              pdf.text w_data[:text], :align => :justify, :inline_format => true
            end
          end
        end
      end
    end

    review_has_potential_nonconformities = grouped_control_objectives.any? do |_, cois|
      cois.any? do |coi|
        !(use_finals ? coi.final_potential_nonconformities : coi.potential_nonconformities).not_revoked.blank?
      end
    end

    if review_has_potential_nonconformities
      pdf.add_subtitle(
        I18n.t('conclusion_review.potential_nonconformities'), PDF_FONT_SIZE, PDF_FONT_SIZE)

      grouped_control_objectives.each do |process_control, cois|
        has_potential_nonconformities = cois.any? do |coi|
          !(use_finals ? coi.final_potential_nonconformities : coi.potential_nonconformities).not_revoked.blank?
        end

        if has_potential_nonconformities
          pc_id = process_control.id.to_s
          column_headers, column_widths = [], []

          column_headers << "<b><i>#{ProcessControl.model_name.human}: " +
              "#{process_control.name}</i></b>"
          column_widths << pdf.percent_width(100)

          cois.each do |coi|
            (use_finals ? coi.final_potential_nonconformities : coi.potential_nonconformities).not_revoked.each do |pnc|
              pnc_data = coi.pdf_data(pnc)

              column_data = []

              unless pnc_data[:column].blank?
                column_data << column_headers
                column_data << pnc_data[:column]

                pdf.move_down PDF_FONT_SIZE

                pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                  table_options = pdf.default_table_options(column_widths)

                  pdf.table(column_data, table_options) do
                    row(0).style(
                      :background_color => 'cccccc',
                      :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                    )
                  end
                end
              end

              pdf.move_down PDF_FONT_SIZE
              pdf.text pnc_data[:text], :align => :justify, :inline_format => true
            end
          end
        end
      end
    end

    review_has_oportunities = grouped_control_objectives.any? do |_, cois|
      cois.any? do |coi|
        !(use_finals ? coi.final_oportunities : coi.oportunities).not_revoked.blank?
      end
    end

    if review_has_oportunities
      pdf.add_subtitle(
        I18n.t('conclusion_review.oportunities'), PDF_FONT_SIZE, PDF_FONT_SIZE)

      grouped_control_objectives.each do |process_control, cois|
        has_oportunities = cois.any? do |coi|
          !(use_finals ? coi.final_oportunities : coi.oportunities).not_revoked.blank?
        end

        if has_oportunities
          pc_id = process_control.id.to_s
          column_headers, column_widths = [], []
          header = "<b><i>#{ProcessControl.model_name.human}: " +
              "#{process_control.name}</i></b>"
          header += " (#{process_control.best_practice.name})" if current_organization.kind.eql?('public')

          column_headers << header
          column_widths << pdf.percent_width(100)

          cois.each do |coi|
            (use_finals ? coi.final_oportunities : coi.oportunities).not_revoked.each do |o|
              o_data = coi.pdf_data(o)

              column_data = []

              unless o_data[:column].blank?
                column_data << column_headers
                column_data << o_data[:column]

                pdf.move_down PDF_FONT_SIZE

                pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
                  table_options = pdf.default_table_options(column_widths)

                  pdf.table(column_data, table_options) do
                    row(0).style(
                      :background_color => 'cccccc',
                      :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
                    )
                  end
                end
              end

              pdf.move_down PDF_FONT_SIZE
              pdf.text o_data[:text], :align => :justify, :inline_format => true
            end
          end
        end
      end
    end

    unless self.review.finding_review_assignments.empty?
      pdf.add_subtitle(I18n.t('conclusion_review.finding_review_assignments'),
        PDF_FONT_SIZE, PDF_FONT_SIZE)
      repeated_findings = self.review.finding_review_assignments.map do |fra|
        "#{fra.finding.to_s} [<b>#{fra.finding.state_text}</b>]"
      end

      pdf.add_list(repeated_findings, PDF_FONT_SIZE)
    end

    pdf.move_down PDF_FONT_SIZE

    pdf.add_review_auditors_table(
      self.review.review_user_assignments.reject { |rua| rua.audited? })

    pdf.custom_save_as self.pdf_name, ConclusionReview.table_name, self.id
  end

  def absolute_pdf_path
    Prawn::Document.absolute_path self.pdf_name, ConclusionReview.table_name,
      self.id
  end

  def relative_pdf_path
    Prawn::Document.relative_path self.pdf_name, ConclusionReview.table_name,
      self.id
  end

  def pdf_name
    identification = self.review.sanitized_identification

    "#{self.class.model_name.human.downcase.gsub(/\s/, '_')}-#{identification}.pdf"
  end

  def create_bundle_zip(organization, index_items)
    cover_paths = []
    cover_count = 1
    zip_path = self.absolute_bundle_zip_path
    zip_filename = File.join(*zip_path)

    self.bundle_index_pdf organization, index_items
    cover_paths << self.absolute_bundle_index_pdf_path

    (index_items || '').each_line do |line|
      unless line.blank?
        pdf_name = "#{'%02d' % cover_count}_#{line.strip.downcase}.pdf".
          sanitized_for_filename

        self.create_cover_pdf(organization, line.strip, pdf_name)

        cover_paths << self.absolute_cover_pdf_path(pdf_name)
        cover_count += 1
      end
    end

    self.create_workflow_pdf(organization)
    cover_paths << self.absolute_workflow_pdf_path

    cois_dir = I18n.t('conclusion_review.bundle.control_objectives_dir',
      :prefix => '%02d' % cover_count).sanitized_for_filename
    cover_count += 1

    self.create_findings_sheet_pdf(organization, cover_count)
    cover_paths << self.absolute_findings_sheet_pdf_path(cover_count)
    cover_count += 1 if File.exist?(cover_paths.last)

    findings_dir = I18n.t('conclusion_review.bundle.findings_dir',
      :prefix => '%02d' % cover_count).sanitized_for_filename
    cover_count += 1 unless self.findings.blank?

    self.create_findings_follow_up_pdf(organization, cover_count)
    cover_paths << self.absolute_findings_follow_up_pdf_path(cover_count)
    cover_count += 1 if File.exist?(cover_paths.last)

    FileUtils.rm zip_filename if File.exist?(zip_filename)

    Zip::File.open(zip_filename, Zip::File::CREATE) do |zipfile|
      cover_paths.each do |cover|
        zipfile.add(File.basename(cover), cover) { true } if File.exist?(cover)
      end

      unless self.control_objective_items.blank?
        zipfile.mkdir cois_dir

        self.control_objective_items.each do |coi|
          coi.to_pdf(organization)
          zipfile.add(File.join(cois_dir, coi.pdf_name),
            coi.absolute_pdf_path) { true }

          cover_paths << coi.absolute_pdf_path
        end
      end

      unless self.findings.blank?
        zipfile.mkdir findings_dir

        self.findings.each do |finding|
          finding.to_pdf(organization)
          zipfile.add(File.join(findings_dir, finding.pdf_name),
            finding.absolute_pdf_path) { true }

          cover_paths << finding.absolute_pdf_path
        end
      end
    end

    cover_paths.each {|cover| FileUtils.rm cover if File.exist?(cover)}

    FileUtils.chmod 0640, zip_filename
  end

  def absolute_bundle_zip_path
    Prawn::Document.absolute_path self.bundle_zip_name, ConclusionReview.table_name,
      self.id
  end

  def relative_bundle_zip_path
    Prawn::Document.relative_path self.bundle_zip_name, ConclusionReview.table_name,
      self.id
  end

  def bundle_zip_name
    I18n.t('conclusion_review.bundle.zip_name',
      :identification => self.review.sanitized_identification)
  end

  def bundle_index_pdf(organization = nil, index_items = nil)
    pdf = Prawn::Document.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?
    items_count = 1

    pdf.add_review_header organization || self.organization,
      self.review.try(:identification),
      self.review.try(:plan_item).try(:project)

    pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

    pdf.move_down((PDF_FONT_SIZE * 1.5).round)

    pdf.add_title I18n.t('conclusion_review.bundle_index.title'),
      (PDF_FONT_SIZE * 1.5).round, :center

    pdf.move_down((PDF_FONT_SIZE * 1.5).round)

    (index_items || '').each_line do |line|
      unless line.blank?
        pdf.text "#{'%02d' % items_count}. #{line.strip}",
          :font_size => (PDF_FONT_SIZE * 1.25).round
        items_count += 1
      end
    end

    pdf.custom_save_as self.bundle_index_pdf_name, ConclusionReview.table_name,
      self.id
  end

  def absolute_bundle_index_pdf_path
    Prawn::Document.absolute_path self.bundle_index_pdf_name,
      ConclusionReview.table_name, self.id
  end

  def relative_bundle_index_pdf_path
    Prawn::Document.relative_path self.bundle_index_pdf_name,
      ConclusionReview.table_name, self.id
  end

  def bundle_index_pdf_name
    I18n.t('conclusion_review.bundle_index.pdf_name')
  end

  def create_cover_pdf(organization = nil, text = nil, pdf_name = 'cover.pdf')
    pdf = Prawn::Document.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?

    pdf.add_review_header organization || self.organization,
      self.review.try(:identification),
      self.review.try(:plan_item).try(:project)

    pdf.move_down PDF_FONT_SIZE * 8

    pdf.add_title text, PDF_FONT_SIZE * 2, :center

    pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, self.id
  end

  def absolute_cover_pdf_path(pdf_name = 'cover.pdf')
    Prawn::Document.absolute_path pdf_name, ConclusionReview.table_name, self.id
  end

  def relative_cover_pdf_path(pdf_name = 'cover.pdf')
    Prawn::Document.relative_path pdf_name, ConclusionReview.table_name, self.id
  end

  def create_workflow_pdf(organization = nil)
    pdf = Prawn::Document.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?

    pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

    pdf.add_review_header organization || self.organization,
      self.review.try(:identification),
      self.review.try(:plan_item).try(:project)

    pdf.move_down((PDF_FONT_SIZE * 1.5).round)

    pdf.add_title I18n.t('conclusion_review.workflow.title'),
      (PDF_FONT_SIZE * 1.5).round, :center

    pdf.move_down((PDF_FONT_SIZE * 1.5).round)

    grouped_control_objectives = self.control_objective_items.group_by(
      &:process_control
    )

    grouped_control_objectives.each do |process_control, cois|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_description_item("#{ProcessControl.model_name.human}",
        process_control.name, 0, false)

      cois.each do |coi|
        pdf.move_down PDF_FONT_SIZE
        pdf.add_description_item(
          "• #{ControlObjectiveItem.model_name.human}", coi.to_s,
          PDF_FONT_SIZE * 2, false
        )

        unless coi.work_papers.blank?
          pdf.move_down PDF_FONT_SIZE
          pdf.text "<b>#{I18n.t(
            'conclusion_review.workflow.control_objective_work_papers')}</b>:",
              :indent_paragraphs => PDF_FONT_SIZE * 4, :inline_format => true

          coi.work_papers.each do |wp|
            pdf.text wp.inspect, :indent_paragraphs => PDF_FONT_SIZE * 6, :inline_format => true
          end
        end

        unless (use_finals ? coi.final_weaknesses : coi.weaknesses).blank?
          pdf.move_down PDF_FONT_SIZE
          pdf.text "<b>#{I18n.t(
            'conclusion_review.workflow.control_objective_weaknesses')}</b>:",
              :indent_paragraphs => PDF_FONT_SIZE * 4, :inline_format => true

          (use_finals ? coi.final_weaknesses : coi.weaknesses).each do |w|
            pdf.text [w.review_code, w.title, w.risk_text, w.state_text].join(' - '),
              :indent_paragraphs => PDF_FONT_SIZE * 6

            unless w.work_papers.blank?
              pdf.move_down PDF_FONT_SIZE
              pdf.text "<b>#{I18n.t(
                'conclusion_review.workflow.weakness_work_papers')}</b>:",
                  :indent_paragraphs => PDF_FONT_SIZE * 8, :inline_format => true

              w.work_papers.each do |wp|
                pdf.text wp.inspect, :indent_paragraphs => PDF_FONT_SIZE * 10
              end

              pdf.move_down PDF_FONT_SIZE
            end
          end
        end

        unless (use_finals ? coi.final_oportunities : coi.oportunities).blank?
          title = I18n.t(
            'conclusion_review.workflow.control_objective_oportunities')

          pdf.move_down PDF_FONT_SIZE
          pdf.text "<b>#{title}</b>:", :indent_paragraphs => PDF_FONT_SIZE * 4, :inline_format => true

          (use_finals ? coi.final_oportunities : coi.oportunities).each do |o|
            pdf.text [o.review_code, o.title, o.state_text].join(' - '),
              :indent_paragraphs => PDF_FONT_SIZE * 6

            unless o.work_papers.blank?
              pdf.move_down PDF_FONT_SIZE
              pdf.text "• <b>#{I18n.t(
                'conclusion_review.workflow.oportunity_work_papers')}</b>:",
                  :indent_paragraphs => PDF_FONT_SIZE * 8, :inline_format => true

              o.work_papers.each do |wp|
                pdf.text wp.inspect, :indent_paragraphs => PDF_FONT_SIZE * 10, :inline_format => true
              end

              pdf.move_down PDF_FONT_SIZE
            end
          end
        end
      end
    end

    pdf.custom_save_as self.workflow_pdf_name, ConclusionReview.table_name,
      self.id
  end

  def absolute_workflow_pdf_path
    Prawn::Document.absolute_path(self.workflow_pdf_name,
      ConclusionReview.table_name, self.id)
  end

  def relative_workflow_pdf_path
    Prawn::Document.relative_path(self.workflow_pdf_name,
      ConclusionReview.table_name, self.id)
  end

  def workflow_pdf_name
    I18n.t('conclusion_review.workflow.pdf_name')
  end

  def create_findings_sheet_pdf(organization = nil, index = 1)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?
    weaknesses = use_finals ? self.review.final_weaknesses :
      self.review.weaknesses

    unless weaknesses.blank?
      pdf = Prawn::Document.create_generic_pdf(:portrait, false)
      pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

      pdf.add_review_header organization || self.organization,
        self.review.try(:identification),
        self.review.try(:plan_item).try(:project)

      pdf.move_down((PDF_FONT_SIZE * 1.5).round)

      pdf.add_title I18n.t('conclusion_review.findings_sheet.title'),
        (PDF_FONT_SIZE * 1.5).round, :center

      pdf.move_down((PDF_FONT_SIZE * 1.5).round)

      weaknesses.sort { |w1, w2| w1.review_code <=> w2.review_code }.each do |w|
        pdf.text [w.review_code, w.title, w.risk_text, w.state_text].join(' - '),
          :font_size => PDF_FONT_SIZE

        w.work_papers.each do |wp|
          pdf.text wp.inspect, :indent_paragraphs => PDF_FONT_SIZE * 2
        end
      end

      pdf.custom_save_as self.findings_sheet_name(index), 'conclusion_reviews',
        self.id
    end
  end

  def absolute_findings_sheet_pdf_path(index = 1)
    Prawn::Document.absolute_path(self.findings_sheet_name(index),
      'conclusion_reviews', self.id)
  end

  def relative_findings_sheet_pdf_path(index = 1)
    Prawn::Document.relative_path(self.findings_sheet_name(index),
      'conclusion_reviews', self.id)
  end

  def findings_sheet_name(index = 1)
    I18n.t('conclusion_review.findings_sheet.pdf_name',
      :prefix => '%02d' % index)
  end

  def create_findings_follow_up_pdf(organization = nil, index = 1)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?
    weaknesses = (use_finals ? self.review.final_weaknesses :
        self.review.weaknesses)
    oportunities = (use_finals ? self.review.final_oportunities :
        self.review.oportunities)

    weaknesses = weaknesses.select do |w|
      w.implemented? || w.being_implemented? || w.unanswered?
    end.sort { |w1, w2| w1.review_code <=> w2.review_code }
    oportunities = oportunities.select do |o|
      o.implemented? || o.being_implemented? || o.unanswered?
    end.sort { |o1, o2| o1.review_code <=> o2.review_code }

    unless (weaknesses + oportunities).blank?
      pdf = Prawn::Document.create_generic_pdf(:portrait, false)
      column_order = [['review_code', 20], ['title', 40], ['risk', 20], ['state', 20]]
      column_data, column_widths, column_headers = [], [], []
      pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals
      pdf.add_review_header organization || self.organization,
        self.review.try(:identification),
        self.review.try(:plan_item).try(:project)

      pdf.move_down((PDF_FONT_SIZE * 1.5).round)

      pdf.add_title I18n.t('conclusion_review.findings_follow_up.title'),
        (PDF_FONT_SIZE * 1.5).round, :center

      column_order.each do |col_name, col_with|
        column_headers << Finding.human_attribute_name(col_name) +
          (['risk', 'state'].include?(col_name) ? ' *' : '')
        column_widths << pdf.percent_width(col_with)
      end

      pdf.move_down PDF_FONT_SIZE * 2 unless weaknesses.blank?

      weaknesses.each do |weakness|
        column_data << [
          weakness.review_code,
          weakness.title,
          weakness.risk_text,
          weakness.state_text
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end

        pdf.text "\n#{
          I18n.t('conclusion_review.findings_follow_up.index_clarification')}",
            :font_size => (PDF_FONT_SIZE * 0.75).round, :align => :justify
      end

      column_data = []

      unless oportunities.blank?
        pdf.move_down PDF_FONT_SIZE * 2
        column_headers.delete_at 1
        column_widths.delete_at 1
      end

      oportunities.each do |oportunity|
        column_data << [
          oportunity.review_code,
          oportunity.title,
          oportunity.state_text
        ]
      end

      unless column_data.blank?
        pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
          table_options = pdf.default_table_options(column_widths)

          pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
          end
        end

        pdf.text "\n#{
          I18n.t('conclusion_review.findings_follow_up.index_clarification')}",
            :font_size => (PDF_FONT_SIZE * 0.75), :align => :justify
      end

      weaknesses.each do |weakness|
        pdf.start_new_page
        pdf.move_down((PDF_FONT_SIZE * 1.5).round)

        pdf.add_title I18n.t(
          'conclusion_review.findings_follow_up.weakness_title_in_singular'),
          (PDF_FONT_SIZE * 1.5).round, :center

        pdf.move_down((PDF_FONT_SIZE * 1.5).round)

        pdf.text [weakness.review_code, weakness.title, weakness.risk_text, weakness.state_text].join(' - '),
          :font_size => PDF_FONT_SIZE, :align => :center
      end

      oportunities.each do |oportunity|
        pdf.start_new_page
        pdf.move_down((PDF_FONT_SIZE * 1.5).round)

        pdf.add_title I18n.t(
          'conclusion_review.findings_follow_up.oportunity_title_in_singular'),
          (PDF_FONT_SIZE * 1.5).round, :center

        pdf.move_down((PDF_FONT_SIZE * 1.5).round)

        pdf.text [oportunity.review_code, oportunity.title, oportunity.state_text].join(' - '),
          :font_size => PDF_FONT_SIZE, :align => :center
      end

      pdf.custom_save_as self.findings_follow_up_name(index),
        ConclusionReview.table_name, self.id
    end
  end

  def absolute_findings_follow_up_pdf_path(index = 1)
    Prawn::Document.absolute_path(self.findings_follow_up_name(index),
      'conclusion_reviews', self.id)
  end

  def relative_findings_follow_up_pdf_path(index = 1)
    Prawn::Document.relative_path(self.findings_follow_up_name(index),
      'conclusion_reviews', self.id)
  end

  def findings_follow_up_name(index = 1)
    I18n.t('conclusion_review.findings_follow_up.pdf_name',
      :prefix => '%02d' % index)
  end
end
