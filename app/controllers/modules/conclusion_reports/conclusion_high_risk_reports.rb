module ConclusionHighRiskReports
  # Crea un PDF con las observaciones por riesgo para un determinado rango
  # de fechas
  #
  # * GET /conclusion_committee_reports/weaknesses_by_risk_report
  def weaknesses_by_risk_report
    @title = t('conclusion_committee_report.weaknesses_by_risk_report_title')
    @from_date, @to_date = *make_date_range(params[:weaknesses_by_risk_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'score',
      'weaknesses_by_risk']
    @filters = []
    @notorious_reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    ).notorious(true)

    if params[:weaknesses_by_risk_report]
      risk = params[:weaknesses_by_risk_report][:risk]

      unless params[:weaknesses_by_risk_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:weaknesses_by_risk_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:weaknesses_by_risk_report][:business_unit].blank?
        business_units =
          params[:weaknesses_by_risk_report][:business_unit].split(
            SPLIT_AND_TERMS_REGEXP
          ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:weaknesses_by_risk_report][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'weaknesses_by_risk' =>
            [t('conclusion_committee_report.weaknesses_by_risk_report_title'), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          weaknesses_by_risk = []
          weaknesses = c_r.review.final_weaknesses.by_risk(risk).
            with_pending_status_for_report

          weaknesses.each do |w|
            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            weaknesses_by_risk << [
              "\n<b>#{Review.model_name.human}</b>: #{w.review.to_s}",
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{Weakness.human_attribute_name(:follow_up_date)}</b>: #{l(w.follow_up_date, :format => :long)}",
              ("<b>#{Weakness.human_attribute_name(:origination_date)}</b>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}",
              "<b>#{Weakness.human_attribute_name(:audit_comments)}</b>: #{w.audit_comments}",
              "<b>#{Weakness.human_attribute_name(:answer)}</b>: #{w.answer}"
            ].compact.join("\n")
          end

          unless weaknesses_by_risk.blank?
            column_data << [
              c_r.review.business_unit.name,
              c_r.review.reload.score_text,
              weaknesses_by_risk
            ]
          end
        end

        unless column_data.blank?
          @notorious_reviews[period] ||= []
          @notorious_reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  # Crea un PDF con las observaciones por riesgo para un determinado rango
  # de fechas
  #
  # * POST /conclusion_committee_reports/create_weaknesses_by_risk_report
  def create_weaknesses_by_risk_report
    self.weaknesses_by_risk_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      unless @notorious_reviews[period].blank?
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
          (PDF_FONT_SIZE * 1.25).round, :left

        pdf.move_down PDF_FONT_SIZE

        @notorious_reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers = [], []

          @column_order.each do |order|
            column_headers << columns[order].first
          end
          if !data[:external] && !@internal_title_showed
            title = t('conclusion_committee_report.weaknesses_by_risk_report.internal_audit_weaknesses')
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t('conclusion_committee_report.weaknesses_by_risk_report.external_audit_weaknesses')
            @external_title_showed = true
          end

          if title
            pdf.move_down PDF_FONT_SIZE * 2
            pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
          end

          pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

          unless data[:column_data].blank?
            pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
              data[:column_data].each do |col_data|
                column_headers.each_with_index do |header, i|
                  if col_data[i].kind_of? Array
                    col_data[i].each do |data|
                      pdf.text data, :inline_format => true
                    end
                  else
                    pdf.text "<b>#{header.upcase}</b>: #{col_data[i]}", :inline_format => true
                  end
                end
              end
            end
          else
            pdf.text(
              t('conclusion_committee_report.weaknesses_by_risk_report.without_audits_in_the_period'),
              :style => :italic
            )
          end
        end
      end
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('conclusion_committee_report.weaknesses_by_risk_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'weaknesses_by_risk_report', 0)
  end

  # Crea un PDF con las observaciones solucionadas para un determinado rango de
  # fechas
  #
  # * GET /conclusion_committee_reports/fixed_weaknesses_report
  def fixed_weaknesses_report
    @title = t('conclusion_committee_report.fixed_weaknesses_report_title')
    @from_date, @to_date = *make_date_range(params[:fixed_weaknesses_report])
    @periods = periods_by_solution_date_for_interval
    @column_order = ['business_unit_report_name', 'score', 'fixed_weaknesses']
    @filters = []
    @reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_final_solution_date(
      @from_date, @to_date
    )

    if params[:fixed_weaknesses_report]
      unless params[:fixed_weaknesses_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:fixed_weaknesses_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:fixed_weaknesses_report][:business_unit].blank?
        business_units = params[:fixed_weaknesses_report][:business_unit].split(
          SPLIT_AND_TERMS_REGEXP
        ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:fixed_weaknesses_report][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'fixed_weaknesses' =>
            [t('conclusion_committee_report.fixed_weaknesses'), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          fixed_weaknesses = []
          weaknesses = c_r.review.final_weaknesses.with_solution_date_between(
            @from_date, @to_date).with_highest_risk

          weaknesses.each do |w|
            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            fixed_weaknesses << [
              "\n<b>#{Review.model_name.human}</b>: #{w.review.to_s}",
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{Weakness.human_attribute_name(:solution_date)}</b>: #{l(w.solution_date, :format => :long)}",
              ("<b>#{Weakness.human_attribute_name(:origination_date)}</b>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}",
              "<b>#{Weakness.human_attribute_name(:audit_comments)}</b>: #{w.audit_comments}",
              "<b>#{Weakness.human_attribute_name(:answer)}</b>: #{w.answer}"
            ].compact.join("\n")
          end

          unless fixed_weaknesses.blank?
            column_data << [
              c_r.review.business_unit.name,
              c_r.review.reload.score_text,
              fixed_weaknesses
            ]
          end
        end

        unless column_data.blank?
          @reviews[period] ||= []
          @reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  # Crea un PDF con las observaciones solucionadas para un determinado rango de
  # fechas
  #
  # * POST /conclusion_committee_reports/create_fixed_weaknesses_report
  def create_fixed_weaknesses_report
    self.fixed_weaknesses_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      unless @reviews[period].blank?
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
          (PDF_FONT_SIZE * 1.25).round, :justify

        pdf.move_down PDF_FONT_SIZE

        @reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers = [], []

          @column_order.each do |column|
            column_headers << columns[column].first
          end

          if !data[:external] && !@internal_title_showed
            title = t('conclusion_committee_report.fixed_weaknesses_report.internal_audit_weaknesses')
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t('conclusion_committee_report.fixed_weaknesses_report.external_audit_weaknesses')
            @external_title_showed = true
          end

          if title
            pdf.move_down PDF_FONT_SIZE * 2
            pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
          end

          pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

          unless data[:column_data].blank?
            pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
              data[:column_data].each do |col_data|
                column_headers.each_with_index do |header, i|
                  if col_data[i].kind_of? Array
                    col_data[i].each do |data|
                      pdf.text data, :inline_format => true
                    end
                  else
                    pdf.text "<b>#{header.upcase}</b>: #{col_data[i]}", :inline_format => true
                  end
                end
              end
            end
          else
            pdf.text(
              t('conclusion_committee_report.fixed_weaknesses_report.without_audits_in_the_period'),
              :style => :italic)
          end
        end
      end
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'fixed_weaknesses_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('conclusion_committee_report.fixed_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'fixed_weaknesses_report', 0)
  end

  def nonconformities_report
    @title = t('conclusion_committee_report.nonconformities_report_title')
    @from_date, @to_date = *make_date_range(params[:nonconformities_report])
    @periods = periods_for_interval
    @column_order = ['business_unit_report_name', 'score',
      'nonconformities']
    @filters = []
    @notorious_reviews = {}
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )

    if params[:nonconformities_report]
      unless params[:nonconformities_report][:business_unit_type].blank?
        @selected_business_unit = BusinessUnitType.find(
          params[:nonconformities_report][:business_unit_type])
        conclusion_reviews = conclusion_reviews.by_business_unit_type(
          @selected_business_unit.id)
        @filters << "<b>#{BusinessUnitType.model_name.human}</b> = " +
          "\"#{@selected_business_unit.name.strip}\""
      end

      unless params[:nonconformities_report][:business_unit].blank?
        business_units =
          params[:nonconformities_report][:business_unit].split(
            SPLIT_AND_TERMS_REGEXP
          ).uniq.map(&:strip)

        unless business_units.empty?
          conclusion_reviews = conclusion_reviews.by_business_unit_names(
            *business_units)
          @filters << "<b>#{BusinessUnit.model_name.human}</b> = " +
            "\"#{params[:nonconformities_report][:business_unit].strip}\""
        end
      end
    end

    @periods.each do |period|
      BusinessUnitType.list.each do |but|
        columns = {
          'business_unit_report_name' => [but.business_unit_label, 15],
          'score' => [Review.human_attribute_name(:score), 15],
          'nonconformities' =>
            [t('conclusion_committee_report.nonconformities_report_title'), 70]
        }
        column_data = []
        name = but.name
        conclusion_review_per_unit_type =
          conclusion_reviews.for_period(period).with_business_unit_type(but.id)

        conclusion_review_per_unit_type.each do |c_r|
          nonconformities = []
          final_nonconformities = c_r.review.final_nonconformities
            final_nonconformities.each do |nc|
            audited = nc.users.select(&:audited?).map do |u|
              nc.process_owners.include?(u) ?
                "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
                u.full_name
            end

            nonconformities << [
              "<b>#{Review.model_name.human}</b>: #{nc.review.to_s}",
              "<b>#{Nonconformity.human_attribute_name(:review_code)}</b>: #{nc.review_code}",
              "<b>#{Nonconformity.human_attribute_name(:state)}</b>: #{nc.state_text}",
              "<b>#{Nonconformity.human_attribute_name(:risk)}</b>: #{nc.risk_text}",
              "<b>#{Nonconformity.human_attribute_name(:follow_up_date)}</b>: #{l(nc.follow_up_date, :format => :long)}",
              ("<b>#{Nonconformity.human_attribute_name(:origination_date)}</b>: #{l(nc.origination_date, :format => :long)}" if nc.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Nonconformity.human_attribute_name(:description)}</b>: #{nc.description}",
              "<b>#{Nonconformity.human_attribute_name(:audit_comments)}</b>: #{nc.audit_comments}",
              "<b>#{Nonconformity.human_attribute_name(:answer)}</b>: #{nc.answer}"
            ].compact.join("\n")
          end

          unless nonconformities.blank?
            column_data << [
              c_r.review.business_unit.name,
              c_r.review.reload.score_text,
              nonconformities
            ]
          end
        end

        unless column_data.blank?
          @notorious_reviews[period] ||= []
          @notorious_reviews[period] << {
            :name => name,
            :external => but.external,
            :columns => columns,
            :column_data => column_data
          }
        end
      end
    end
  end

  def create_nonconformities_report
    self.nonconformities_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header @auth_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('conclusion_committee_report.period.title'),
      t('conclusion_committee_report.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      unless @notorious_reviews[period].blank?
        pdf.move_down PDF_FONT_SIZE
        pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
          (PDF_FONT_SIZE * 1.25).round, :left

        pdf.move_down PDF_FONT_SIZE

        @notorious_reviews[period].each do |data|
          columns = data[:columns]
          column_data, column_headers = [], []

          @column_order.each do |order|
            column_headers << columns[order].first
          end
          if !data[:external] && !@internal_title_showed
            title = t('conclusion_committee_report.nonconformities_report.internal_audit_nonconformities')
            @internal_title_showed = true
          elsif data[:external] && !@external_title_showed
            title = t('conclusion_committee_report.nonconformities_report.external_audit_nonconformities')
            @external_title_showed = true
          end

          if title
            pdf.move_down PDF_FONT_SIZE * 2
            pdf.add_title title, (PDF_FONT_SIZE * 1.25).round, :center
          end

          pdf.add_subtitle data[:name], PDF_FONT_SIZE, PDF_FONT_SIZE

          unless data[:column_data].blank?
            pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
              data[:column_data].each do |col_data|
                column_headers.each_with_index do |header, i|
                  if col_data[i].kind_of?(Array)
                    pdf.text "<b>#{header.upcase}</b>:", :inline_format => true
                    pdf.move_down PDF_FONT_SIZE
                    col_data[i].each do |data|
                      pdf.text data, :inline_format => true
                      pdf.move_down PDF_FONT_SIZE
                    end
                    pdf.move_down PDF_FONT_SIZE
                  else
                    pdf.text "<b>#{header.upcase}</b>: #{col_data[i]}", :inline_format => true
                    pdf.move_down PDF_FONT_SIZE
                  end
                end
              end
            end
          else
            pdf.text(
              t('conclusion_committee_report.nonconformities_report.without_audits_in_the_period'),
              :style => :italic
            )
          end
        end
      end
    end

    unless @filters.empty?
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('conclusion_committee_report.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t('conclusion_committee_report.nonconformities_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'nonconformities_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('conclusion_committee_report.nonconformities_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'nonconformities_report', 0)
  end

  private

  def periods_by_solution_date_for_interval
    Period.includes(:reviews => [
        :conclusion_final_review, {:control_objective_items => :final_weaknesses}]
    ).where(
      [
        "#{Weakness.table_name}.solution_date BETWEEN :from_date AND :to_date",
        "#{Period.table_name}.organization_id = :organization_id"
      ].join(' AND '),
      {
        :from_date => @from_date,
        :to_date => @to_date,
        :organization_id => @auth_organization.id
      }
    )
  end
end
