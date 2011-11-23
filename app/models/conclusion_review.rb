require 'pdf/simpletable'

class ConclusionReview < ActiveRecord::Base
  include ParameterSelector
  
  has_paper_trail :meta => {
    :organization_id => lambda { GlobalModelConfig.current_organization_id }
  }

  # Constantes
  GENERIC_COLUMNS_FOR_SEARCH = {
    :issue_date => {
      :column => "#{table_name}.issue_date",
      :operator => SEARCH_ALLOWED_OPERATORS.values, :mask => "%s",
      :conversion_method => lambda { |value|
        Timeliness.parse(value, :date).to_s(:db)
      },
      :regexp => SEARCH_DATE_REGEXP
    },
    :period => {
      :column => "#{Period.table_name}.number", :operator => '=', :mask => "%d",
      :conversion_method => :to_i, :regexp => /\A\s*\d+\s*\Z/
    },
    :identification => {
      :column => "LOWER(#{Review.table_name}.identification)",
      :operator => 'LIKE', :mask => "%%%s%%", :conversion_method => :to_s,
      :regexp => /.*/
    },
    :business_unit => {
      :column => "LOWER(#{BusinessUnit.table_name}.name)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    },
    :project => {
      :column => "LOWER(#{PlanItem.table_name}.project)", :operator => 'LIKE',
      :mask => "%%%s%%", :conversion_method => :to_s, :regexp => /.*/
    }
  }.with_indifferent_access

  # Named scopes
  scope :for_period, lambda { |period|
    includes(:review =>:period).where("#{Period.table_name}.id" => period.id)
  }
  scope :by_business_unit_type, lambda { |business_unit_type|
    includes(
      :review => {:plan_item => {:business_unit => :business_unit_type}}
    ).where("#{BusinessUnitType.table_name}.id" => business_unit_type)
  }
  scope :by_business_unit_names, lambda { |*business_unit_names|
    conditions = []
    parameters = {}

    business_unit_names.each_with_index do |business_unit_name, i|
      conditions << "LOWER(#{BusinessUnit.table_name}.name) LIKE :bu_#{i}"
      parameters[:"bu_#{i}"] = Unicode::downcase("%#{business_unit_name}%")
    end

    includes(:plan_item => :business_unit).where(
      conditions.join(' OR '), parameters
    )
  }
  scope :notorious, lambda { |final|
     includes(:review => {
         :control_objective_items => (final ? :final_weaknesses : :weaknesses)}
     ).where(
       "#{Weakness.table_name}.risk = #{Weakness.table_name}.highest_risk"
    )
  }
  scope :with_business_unit_type, lambda { |but_id|
    includes(:review => :business_unit).where(
      "#{BusinessUnit.table_name}.business_unit_type_id" => but_id
    )
  }

  # Callbacks
  before_destroy :can_be_destroyed?

  # Restricciones de los atributos
  attr_protected :approved
  attr_readonly :review_id
  
  # Restricciones
  validates :review_id, :presence => true
  validates :issue_date, :applied_procedures, :conclusion, :presence => true
  validates_length_of :type, :maximum => 255, :allow_nil => true,
    :allow_blank => true
  validates_date :issue_date, :allow_nil => true, :allow_blank => true

  # Relaciones
  belongs_to :review
  has_one :plan_item, :through => :review
  has_many :control_objective_items, :through => :review

  def self.columns_for_sort
    HashWithIndifferentAccess.new({
      :issue_date => {
        :name => ConclusionReview.human_attribute_name(:issue_date),
        :field => "#{ConclusionReview.table_name}.issue_date ASC"
      },
      :period => {
        :name => Period.model_name.human,
        :field => "#{Period.table_name}.number ASC"
      },
      :identification => {
        :name => Review.human_attribute_name(:identification),
        :field => "#{Review.table_name}.identification ASC"
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
    Notifier.conclusion_review_notification(user, self, options).deliver
  end

  def to_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) || self.has_final_review?
    cover_text = "\n\n\n\n#{Review.model_name.human.upcase}\n\n"
    cover_text << "#{self.review.identification}\n\n"
    cover_text << "#{self.review.plan_item.project}\n\n\n\n\n\n"
    cover_bottom_text = "#{self.review.plan_item.business_unit.name}\n"
    cover_bottom_text << I18n.l(self.issue_date, :format => :long)

    pdf.add_review_header organization, self.review.identification.strip,
      self.review.plan_item.project.strip

    if self.instance_of?(ConclusionDraftReview)
      pdf.add_watermark(self.class.model_name.human)
    end

    pdf.add_title cover_text, (PDF_FONT_SIZE * 1.5).round, :center, false
    pdf.add_title cover_bottom_text, (PDF_FONT_SIZE * 1.25).round, :center,
      false

    pdf.start_new_page true
    pdf.add_page_footer

    pdf.add_title self.review.description

    pdf.move_pointer PDF_FONT_SIZE

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

    grouped_control_objectives = self.review.grouped_control_objective_items

    grouped_control_objectives.each do |process_control, cois|
      pdf.text "<b>#{ProcessControl.model_name.human}: " +
          "<i>#{process_control.name}</i></b>", :justification => :full

      cois.sort.each do |coi|
        pdf.text "<C:bullet/> #{coi}", :left => PDF_FONT_SIZE * 2,
          :justification => :full
      end
    end

    unless self.applied_procedures.blank?
      pdf.add_subtitle I18n.t('conclusion_review.applied_procedures'),
        PDF_FONT_SIZE
      pdf.text self.applied_procedures, :justification => :full
    end

    pdf.add_subtitle I18n.t('conclusion_review.conclusion'), PDF_FONT_SIZE

    pdf.move_pointer PDF_FONT_SIZE

    self.review.add_score_details_table(pdf)

    pdf.move_pointer((PDF_FONT_SIZE * 0.75).round)
    pdf.text "<i>#{I18n.t('review.review_qualification_explanation')}</i>",
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full

    unless self.conclusion.blank?
      pdf.move_pointer PDF_FONT_SIZE
      pdf.text self.conclusion, :justification => :full,
        :font_size => PDF_FONT_SIZE
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
          columns = {}

          columns[pc_id] = PDF::SimpleTable::Column.new(pc_id) do |c|
            c.heading = "<b><i>#{ProcessControl.model_name.human}: " +
              "#{process_control.name}</i></b>"
            c.justification = :full
            c.width = pdf.percent_width(100)
          end

          cois.each do |coi|
            weaknesses = (
              use_finals ? coi.final_weaknesses : coi.weaknesses
            ).not_revoked.order('review_code ASC')
            
            weaknesses.each do |w|
              w_data = coi.pdf_data(w, pc_id)
              
              unless w_data[:column].blank?
                pdf.move_pointer PDF_FONT_SIZE
                
                PDF::SimpleTable.new do |table|
                  table.width = pdf.page_usable_width
                  table.columns = columns
                  table.data = [w_data[:column]]
                  table.column_order = [pc_id]
                  table.row_gap = (PDF_FONT_SIZE * 0.75).round
                  table.split_rows = true
                  table.font_size = PDF_FONT_SIZE
                  table.shade_color = Color::RGB.from_percentage(95, 95, 95)
                  table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
                  table.heading_font_size = PDF_FONT_SIZE
                  table.shade_headings = true
                  table.position = :left
                  table.orientation = :right
                  table.render_on pdf
                end
              end

              pdf.move_pointer PDF_FONT_SIZE
              pdf.text w_data[:text], :justification => :full
            end
          end
        end
      end
    end

    review_has_oportunities = grouped_control_objectives.any? do |_, cois|
      cois.any? do |coi|
        !(use_finals ? coi.final_oportunities : coi.oportunities).blank?
      end
    end

    if review_has_oportunities
      pdf.add_subtitle(
        I18n.t('conclusion_review.oportunities'), PDF_FONT_SIZE, PDF_FONT_SIZE)

      grouped_control_objectives.each do |process_control, cois|
        has_oportunities = cois.any? do |coi|
          !(use_finals ? coi.final_oportunities : coi.oportunities).blank?
        end

        if has_oportunities
          pc_id = process_control.id.to_s
          columns = {}

          columns[pc_id] = PDF::SimpleTable::Column.new(pc_id) do |c|
            c.heading = "<b><i>#{ProcessControl.model_name.human}: " +
              "#{process_control.name}</i></b>"
            c.justification = :full
            c.width = pdf.percent_width(100)
          end

          cois.each do |coi|
            (use_finals ? coi.final_oportunities : coi.oportunities).each do |o|
              o_data = coi.pdf_data(o, pc_id)
              
              unless o_data[:column].blank?
                pdf.move_pointer PDF_FONT_SIZE
                
                PDF::SimpleTable.new do |table|
                  table.width = pdf.page_usable_width
                  table.columns = columns
                  table.data = [o_data[:column]]
                  table.column_order = [pc_id]
                  table.row_gap = (PDF_FONT_SIZE * 0.75).round
                  table.split_rows = true
                  table.font_size = PDF_FONT_SIZE
                  table.shade_color = Color::RGB.from_percentage(95, 95, 95)
                  table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
                  table.heading_font_size = PDF_FONT_SIZE
                  table.shade_headings = true
                  table.position = :left
                  table.orientation = :right
                  table.render_on pdf
                end
              end

              pdf.move_pointer PDF_FONT_SIZE
              pdf.text o_data[:text], :justification => :full
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

    pdf.move_pointer PDF_FONT_SIZE

    pdf.add_review_auditors_table(
      self.review.review_user_assignments.reject { |rua| rua.audited? })

    pdf.custom_save_as self.pdf_name, ConclusionReview.table_name, self.id
  end

  def absolute_pdf_path
    PDF::Writer.absolute_path self.pdf_name, ConclusionReview.table_name,
      self.id
  end

  def relative_pdf_path
    PDF::Writer.relative_path self.pdf_name, ConclusionReview.table_name,
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

    Zip::ZipFile.open(zip_filename, Zip::ZipFile::CREATE) do |zipfile|
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
    PDF::Writer.absolute_path self.bundle_zip_name, ConclusionReview.table_name,
      self.id
  end

  def relative_bundle_zip_path
    PDF::Writer.relative_path self.bundle_zip_name, ConclusionReview.table_name,
      self.id
  end

  def bundle_zip_name
    I18n.t('conclusion_review.bundle.zip_name',
      :identification => self.review.sanitized_identification)
  end

  def bundle_index_pdf(organization = nil, index_items = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?
    items_count = 1

    pdf.add_review_header organization || self.review.try(:organization),
      self.review.try(:identification),
      self.review.try(:plan_item).try(:project)

    pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

    pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

    pdf.add_title I18n.t('conclusion_review.bundle_index.title'),
      (PDF_FONT_SIZE * 1.5).round, :center

    pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

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
    PDF::Writer.absolute_path self.bundle_index_pdf_name,
      ConclusionReview.table_name, self.id
  end

  def relative_bundle_index_pdf_path
    PDF::Writer.relative_path self.bundle_index_pdf_name,
      ConclusionReview.table_name, self.id
  end

  def bundle_index_pdf_name
    I18n.t('conclusion_review.bundle_index.pdf_name')
  end

  def create_cover_pdf(organization = nil, text = nil, pdf_name = 'cover.pdf')
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?

    pdf.add_review_header organization || self.review.try(:organization),
      self.review.try(:identification),
      self.review.try(:plan_item).try(:project)

    pdf.move_pointer PDF_FONT_SIZE * 8

    pdf.add_title text, PDF_FONT_SIZE * 2, :center

    pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

    pdf.custom_save_as pdf_name, ConclusionReview.table_name, self.id
  end

  def absolute_cover_pdf_path(pdf_name = 'cover.pdf')
    PDF::Writer.absolute_path pdf_name, ConclusionReview.table_name, self.id
  end

  def relative_cover_pdf_path(pdf_name = 'cover.pdf')
    PDF::Writer.relative_path pdf_name, ConclusionReview.table_name, self.id
  end

  def create_workflow_pdf(organization = nil)
    pdf = PDF::Writer.create_generic_pdf(:portrait, false)
    use_finals = !self.kind_of?(ConclusionDraftReview) ||
      self.review.has_final_review?

    pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

    pdf.add_review_header organization || self.review.try(:organization),
      self.review.try(:identification),
      self.review.try(:plan_item).try(:project)

    pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

    pdf.add_title I18n.t('conclusion_review.workflow.title'),
      (PDF_FONT_SIZE * 1.5).round, :center

    pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

    grouped_control_objectives = self.control_objective_items.group_by(
      &:process_control
    )

    grouped_control_objectives.each do |process_control, cois|
      pdf.move_pointer PDF_FONT_SIZE
      pdf.add_description_item("#{ProcessControl.model_name.human}",
        process_control.name, 0, false)

      cois.each do |coi|
        pdf.move_pointer PDF_FONT_SIZE
        pdf.add_description_item(
          "<C:bullet/> #{ControlObjectiveItem.model_name.human}", coi.to_s,
          PDF_FONT_SIZE * 2, false
        )

        unless coi.work_papers.blank?
          pdf.move_pointer PDF_FONT_SIZE
          pdf.text "<C:disc/> <b>#{I18n.t(
            'conclusion_review.workflow.control_objective_work_papers')}</b>:",
              :left => PDF_FONT_SIZE * 4

          coi.work_papers.each do |wp|
            pdf.text wp.inspect, :left => PDF_FONT_SIZE * 6
          end
        end

        unless (use_finals ? coi.final_weaknesses : coi.weaknesses).blank?
          pdf.move_pointer PDF_FONT_SIZE
          pdf.text "<C:disc/> <b>#{I18n.t(
            'conclusion_review.workflow.control_objective_weaknesses')}</b>:",
              :left => PDF_FONT_SIZE * 4

          (use_finals ? coi.final_weaknesses : coi.weaknesses).each do |w|
            pdf.text [w.review_code, w.risk_text, w.state_text].join(' - '),
              :left => PDF_FONT_SIZE * 6

            unless w.work_papers.blank?
              pdf.move_pointer PDF_FONT_SIZE
              pdf.text "<C:bullet/> <b>#{I18n.t(
                'conclusion_review.workflow.weakness_work_papers')}</b>:",
                  :left => PDF_FONT_SIZE * 8

              w.work_papers.each do |wp|
                pdf.text wp.inspect, :left => PDF_FONT_SIZE * 10
              end

              pdf.move_pointer PDF_FONT_SIZE
            end
          end
        end

        unless (use_finals ? coi.final_oportunities : coi.oportunities).blank?
          title = I18n.t(
            'conclusion_review.workflow.control_objective_oportunities')

          pdf.move_pointer PDF_FONT_SIZE
          pdf.text "<C:disc/> <b>#{title}</b>:", :left => PDF_FONT_SIZE * 4

          (use_finals ? coi.final_oportunities : coi.oportunities).each do |o|
            pdf.text [o.review_code, o.state_text].join(' - '),
              :left => PDF_FONT_SIZE * 6

            unless o.work_papers.blank?
              pdf.move_pointer PDF_FONT_SIZE
              pdf.text "<C:bullet/> <b>#{I18n.t(
                'conclusion_review.workflow.oportunity_work_papers')}</b>:",
                  :left => PDF_FONT_SIZE * 8

              o.work_papers.each do |wp|
                pdf.text wp.inspect, :left => PDF_FONT_SIZE * 10
              end
              
              pdf.move_pointer PDF_FONT_SIZE
            end
          end
        end
      end
    end

    pdf.custom_save_as self.workflow_pdf_name, ConclusionReview.table_name,
      self.id
  end

  def absolute_workflow_pdf_path
    PDF::Writer.absolute_path(self.workflow_pdf_name,
      ConclusionReview.table_name, self.id)
  end

  def relative_workflow_pdf_path
    PDF::Writer.relative_path(self.workflow_pdf_name,
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
      pdf = PDF::Writer.create_generic_pdf(:portrait, false)
      pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals

      pdf.add_review_header organization || self.review.try(:organization),
        self.review.try(:identification),
        self.review.try(:plan_item).try(:project)

      pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

      pdf.add_title I18n.t('conclusion_review.findings_sheet.title'),
        (PDF_FONT_SIZE * 1.5).round, :center

      pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

      weaknesses.sort {|w1, w2| w1.review_code <=> w2.review_code}.each do |w|
        pdf.text [w.review_code, w.risk_text, w.state_text].join(' - '),
          :font_size => PDF_FONT_SIZE

        w.work_papers.each do |wp|
          pdf.text wp.inspect, :left => PDF_FONT_SIZE * 2
        end
      end

      pdf.custom_save_as self.findings_sheet_name(index), 'conclusion_reviews',
        self.id
    end
  end

  def absolute_findings_sheet_pdf_path(index = 1)
    PDF::Writer.absolute_path(self.findings_sheet_name(index),
      'conclusion_reviews', self.id)
  end

  def relative_findings_sheet_pdf_path(index = 1)
    PDF::Writer.relative_path(self.findings_sheet_name(index),
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
    end.sort {|w1, w2| w1.review_code <=> w2.review_code}
    oportunities = oportunities.select do |o|
      o.implemented? || o.being_implemented? || o.unanswered?
    end.sort {|o1, o2| o1.review_code <=> o2.review_code}

    unless (weaknesses + oportunities).blank?
      pdf = PDF::Writer.create_generic_pdf(:portrait, false)
      column_order = [['review_code', 30], ['risk', 30], ['state', 40]]
      columns = {}
      column_data = []
      pdf.add_watermark(I18n.t('pdf.draft')) unless use_finals
      pdf.add_review_header organization || self.review.try(:organization),
        self.review.try(:identification),
        self.review.try(:plan_item).try(:project)

      pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

      pdf.add_title I18n.t('conclusion_review.findings_follow_up.title'),
        (PDF_FONT_SIZE * 1.5).round, :center

      column_order.each do |col_name, col_with|
        columns[col_name] = PDF::SimpleTable::Column.new(col_name) do |c|
          c.heading = Finding.human_attribute_name(col_name) +
            (['risk', 'state'].include?(col_name) ? ' *' : '')
          c.width = pdf.percent_width(col_with)
        end
      end

      pdf.move_pointer PDF_FONT_SIZE * 2 unless weaknesses.blank?

      weaknesses.each do |weakness|
        column_data << {
          'review_code' => weakness.review_code.to_iso,
          'risk' => weakness.risk_text.to_iso,
          'state' => weakness.state_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = column_order.map(&:first)
          table.split_rows = true
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end

        pdf.text "\n#{
          I18n.t('conclusion_review.findings_follow_up.index_clarification')}",
            :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
      end
      
      column_data = []

      unless oportunities.blank?
        pdf.move_pointer PDF_FONT_SIZE * 2
        column_order.delete_at 1
        columns.delete 'risk'
      end

      oportunities.each do |oportunity|
        column_data << {
          'review_code' => oportunity.review_code.to_iso,
          'state' => oportunity.state_text.to_iso
        }
      end

      unless column_data.blank?
        PDF::SimpleTable.new do |table|
          table.width = pdf.page_usable_width
          table.columns = columns
          table.data = column_data
          table.column_order = column_order.map(&:first)
          table.split_rows = true
          table.font_size = (PDF_FONT_SIZE * 0.75).round
          table.shade_color = Color::RGB.from_percentage(95, 95, 95)
          table.shade_heading_color = Color::RGB.from_percentage(85, 85, 85)
          table.heading_font_size = PDF_FONT_SIZE
          table.shade_headings = true
          table.position = :left
          table.orientation = :right
          table.render_on pdf
        end

        pdf.text "\n#{
          I18n.t('conclusion_review.findings_follow_up.index_clarification')}",
            :font_size => (PDF_FONT_SIZE * 0.75), :justification => :full
      end

      weaknesses.each do |weakness|
        pdf.start_new_page
        pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

        pdf.add_title I18n.t(
          'conclusion_review.findings_follow_up.weakness_title_in_singular'),
          (PDF_FONT_SIZE * 1.5).round, :center

        pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

        pdf.text [weakness.review_code, weakness.risk_text,
          weakness.state_text].join(' - '), :font_size => PDF_FONT_SIZE,
          :justification => :center
      end

      oportunities.each do |oportunity|
        pdf.start_new_page
        pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

        pdf.add_title I18n.t(
          'conclusion_review.findings_follow_up.oportunity_title_in_singular'),
          (PDF_FONT_SIZE * 1.5).round, :center

        pdf.move_pointer((PDF_FONT_SIZE * 1.5).round)

        pdf.text [oportunity.review_code, oportunity.state_text].join(' - '),
          :font_size => PDF_FONT_SIZE, :justification => :center
      end

      pdf.custom_save_as self.findings_follow_up_name(index),
        ConclusionReview.table_name, self.id
    end
  end

  def absolute_findings_follow_up_pdf_path(index = 1)
    PDF::Writer.absolute_path(self.findings_follow_up_name(index),
      'conclusion_reviews', self.id)
  end

  def relative_findings_follow_up_pdf_path(index = 1)
    PDF::Writer.relative_path(self.findings_follow_up_name(index),
      'conclusion_reviews', self.id)
  end

  def findings_follow_up_name(index = 1)
    I18n.t('conclusion_review.findings_follow_up.pdf_name',
      :prefix => '%02d' % index)
  end
end