module Reports::Pdf

  def init_pdf(title, subtitle)
    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization

    pdf.add_title title, PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    if subtitle
      pdf.add_title subtitle, PDF_FONT_SIZE, :center
      pdf.move_down PDF_FONT_SIZE * 2
    end

    pdf
  end

  def add_period_title(pdf, period, align = :left)
    pdf.move_down PDF_FONT_SIZE

    pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
      (PDF_FONT_SIZE * 1.25).round, align

    pdf.move_down PDF_FONT_SIZE
  end

  def add_weaknesses_synthesis_table(pdf, data, font_size = PDF_FONT_SIZE)
    if data.kind_of?(Hash)
      columns = {}
      column_data, column_headers, column_widths = [], [], []

      data[:order].each do |column|
        col_data = data[:columns][column]
        column_headers << "<b>#{col_data.first}</b>"
        column_widths << pdf.percent_width(col_data.last)
      end

      data[:data].each do |row|
        new_row = []

        data[:order].each {|column| new_row << row[column]}

        column_data << new_row
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
      end
    else
      pdf.text data, :style => :italic, :font_size => PDF_FONT_SIZE
    end
  end

  def get_weaknesses_synthesis_table_data(weaknesses_count,
      weaknesses_count_by_risk, risk_levels)
    total_count = weaknesses_count_by_risk.sum(&:second)

    unless total_count == 0
      risk_level_values = risk_levels.map { |rl| rl[0] }.reverse
      statuses = Finding::STATUS.except(*Finding::EXCLUDE_FROM_REPORTS_STATUS).
        sort { |s1, s2| s1.last <=> s2.last }
      column_order = ['state', risk_level_values, 'count'].flatten
      column_data = []
      columns = {
        'state' => [Weakness.human_attribute_name('state'), 30],
        'count' => [Weakness.human_attribute_name('count'), 15]
      }

      risk_levels.each {|rl| columns[rl[0]] = [t("risk_types.#{rl[0]}"), (55 / risk_levels.size)]}

      statuses.each do |state|
        sub_total_count = weaknesses_count[state.last].sum(&:second)
        percentage_total = 0
        column_row = {'state' => "<strong>#{t("finding.status_#{state.first}")}</strong>"}

        risk_levels.each do |rl|
          highest_risk = risk_levels.sort {|r1, r2| r1[1] <=> r2[1]}.last
          count = weaknesses_count[state.last][rl.last]
          percentage = sub_total_count > 0 ?
            (count * 100.0 / sub_total_count).round(2) : 0.0

          column_row[rl.first] = count > 0 ?
            "#{count} (#{'%.2f' % percentage}%)" : '-'
          percentage_total += percentage

          if count > 0 && rl == highest_risk && state[0].to_s == 'being_implemented'
            column_row[rl.first] << '**'
          end
        end

        column_row['count'] = sub_total_count > 0 ?
          "<strong>#{sub_total_count} (#{'%.1f' % percentage_total}%)</strong>" : '-'

        if state.first.to_s == 'being_implemented' && sub_total_count != 0
          column_row['count'] << '*'
        end

        column_data << column_row
      end

      column_row = {
        'state' => "<strong>#{t('follow_up_committee_report.weaknesses_by_risk.total')}</strong>",
        'count' => "<strong>#{total_count}</strong>"
      }

      weaknesses_count_by_risk.each do |risk, count|
        column_row[risk] = "<strong>#{count}</strong>"
      end

      column_data << column_row

      {:order => column_order, :data => column_data, :columns => columns}
    else
      t('follow_up_committee_report.without_weaknesses')
    end
  end

  def add_weaknesses_by_state_table(pdf, weaknesses_count, oportunities_count,
      repeated_count, being_implemented_resume, audit_type_symbol = :internal, nonconformities_count = nil,
      potential_nonconformities_count = nil, sqm = false)

    total_weaknesses = weaknesses_count.values.sum
    total_oportunities = oportunities_count.values.sum

    if sqm
      total_nonconformities = nonconformities_count.values.sum
      total_potential_nonconformities = potential_nonconformities_count.values.sum
      totals = total_weaknesses + total_oportunities + total_nonconformities +
        total_potential_nonconformities
    else
      totals = total_weaknesses + total_oportunities
    end

    if totals > 0
      columns = [
        [Finding.human_attribute_name(:state), 20],
        [t('conclusion_committee_report.weaknesses_by_state.weaknesses_column'), 20]
      ]
      column_data = []

      if audit_type_symbol == :internal && !sqm
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.oportunities_column'), 20]
      elsif audit_type_symbol == :internal && sqm
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.oportunities_column'), 20]
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.nonconformities_column'), 20]
        columns << [
          t('conclusion_committee_report.weaknesses_by_state.potential_nonconformities_column'), 20]
      end

      column_headers, column_widths = [], []

      columns.each do |col_data|
        column_headers << "<strong>#{col_data.first}</strong>"
        column_widths << pdf.percent_width(col_data.last)
      end

      @status.each do |state|
        w_count = weaknesses_count[state.last] || 0
        o_count = oportunities_count[state.last] || 0
        weaknesses_percentage = total_weaknesses > 0 ?
          w_count.to_f / total_weaknesses * 100 : 0.0
        oportunities_percentage = total_oportunities > 0 ?
          o_count.to_f / total_oportunities * 100 : 0.0

        column_data << [
          "<strong>#{t("finding.status_#{state.first}")}</strong>",
          "#{w_count} (#{'%.2f' % weaknesses_percentage.round(2)}%)"
        ]

        if audit_type_symbol == :internal && !sqm
          column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
        elsif audit_type_symbol == :internal && sqm
          nc_count = nonconformities_count[state.last] || 0
          pnc_count = potential_nonconformities_count[state.last] || 0
          nonconformities_percentage = total_nonconformities > 0 ? nc_count.to_f / total_nonconformities * 100 : 0.0
          potential_nonconformities_percentage = total_potential_nonconformities > 0 ? pnc_count.to_f / total_potential_nonconformities * 100 : 0.0

          column_data.last << "#{o_count} (#{'%.2f' % oportunities_percentage.round(2)}%)"
          column_data.last << "#{nc_count} (#{'%.2f' % nonconformities_percentage.round(2)}%)"
          column_data.last << "#{pnc_count} (#{'%.2f' % potential_nonconformities_percentage.round(2)}%)"
        end

        if state.first.to_s == 'being_implemented'
          if column_data.last[1] != '0'
            column_data.last[1] << ' *'
          end
        end
      end

      column_data << [
        "<strong>#{t('follow_up_committee_report.weaknesses_by_state.total')}</strong>",
        "<strong>#{total_weaknesses}</strong>"
      ]

      if audit_type_symbol == :internal && !sqm
        column_data.last << "<strong>#{total_oportunities}</strong>"
      elsif audit_type_symbol == :internal && sqm
        column_data.last << "<strong>#{total_oportunities}</strong>"
        column_data.last << "<strong>#{total_nonconformities}</strong>"
        column_data.last << "<strong>#{total_potential_nonconformities}</strong>"
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
      end

      add_being_implemented_resume(pdf, being_implemented_resume)

      if repeated_count > 0
        pdf.move_down((PDF_FONT_SIZE * 0.5).round)
        pdf.text t('follow_up_committee_report.repeated_count',
          :count => repeated_count, :font_size => PDF_FONT_SIZE)
      end
    else
      pdf.text t('follow_up_committee_report.without_weaknesses'),
        :font_size => PDF_FONT_SIZE, :style => :italic
    end
  end

  def add_being_implemented_resume(pdf, being_implemented_resume = nil,
      asterisks = 1)
    unless being_implemented_resume.blank?
      pdf.move_down PDF_FONT_SIZE if asterisks == 1

      pdf.text(('*' * asterisks) + " #{being_implemented_resume}",
        :font_size => PDF_FONT_SIZE, :inline_format => true)
    end
  end

  def being_implemented_resume_from_counts(being_implemented_counts = {})
    being_implemented_resume = []
    total_of_being_implemented = being_implemented_counts.values.sum
    sub_statuses = [:current, :current_rescheduled, :stale, :stale_rescheduled]

    sub_statuses.each do |sub_status|
      count = being_implemented_counts[sub_status]
      sub_status_percentage = count == 0 ?
        0.00 : (count.to_f / total_of_being_implemented) * 100
      sub_status_resume = "<b>#{count}</b> "
      sub_status_resume << t(
        "follow_up_committee_report.weaknesses_being_implemented_#{sub_status}",
        :count => count)
      sub_status_resume << " (#{'%.2f' % sub_status_percentage}%)"

      being_implemented_resume << sub_status_resume
    end

    unless being_implemented_resume.blank? || total_of_being_implemented == 0
      being_implemented_resume.to_sentence
    end
  end

  def add_pdf_description(pdf, controller, from_date, to_date)
    pdf.add_description_item(
      t("#{controller}_committee_report.period.title"),
      t("#{controller}_committee_report.period.range",
        :from_date => l(from_date, :format => :long),
        :to_date => l(to_date, :format => :long)))
  end

  def add_pdf_filters(pdf, controller, filters)
    pdf.move_down PDF_FONT_SIZE
    pdf.text t("#{controller}_committee_report.applied_filters",
      :filters => filters.to_sentence, :count => filters.size),
      :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
      :inline_format => true
  end

  def save_pdf(pdf, controller, from_date, to_date, sub_directory, id = 0)
    pdf.custom_save_as(
      t("#{controller}_committee_report.#{sub_directory}.pdf_name",
        :from_date => from_date.to_formatted_s(:db),
        :to_date => to_date.to_formatted_s(:db)), sub_directory, id
    )
  end

  def redirect_to_pdf(controller, from_date, to_date, sub_directory, id = 0)
    @report_path = Prawn::Document.relative_path(
      t("#{controller}_committee_report.#{sub_directory}.pdf_name",
        :from_date => from_date.to_formatted_s(:db),
        :to_date => to_date.to_formatted_s(:db)), sub_directory, id
    )

    respond_to do |format|
      format.html { redirect_to @report_path }
      format.js { render 'shared/pdf_report' }
    end
  end
end
