module ConclusionCommitteeReportsHelper
  def synthesis_report_score_average(title, inherent_risks, residual_risks)
    unless inherent_risks.blank?
      raw("<strong>#{title}</strong>: <em>#{((residual_risks.sum.to_f / inherent_risks.sum.to_f) * 100).round}%</em>")
    else
      t('conclusion_committee_report.synthesis_report.without_audits_in_the_period')
    end
  end

  def synthesis_report_organization_score_average(audits_by_business_unit)
    internal_audits_by_business_unit = audits_by_business_unit.reject do |but|
      but[:external]
    end

    unless internal_audits_by_business_unit.blank?
      count = 0
      total = internal_audits_by_business_unit.inject(0) do |sum, data|
        inherent_risks = data[:inherent_risks]
        residual_risks = data[:residual_risks]

        if inherent_risks.blank?
          sum
        else
          count += 1
          sum + ((residual_risks.sum.to_f / inherent_risks.sum.to_f) * 100).round
        end
      end

      average_score = count > 0 ? (total.to_f / count).round : 100
    end

    t(
      'conclusion_committee_report.synthesis_report.organization_score',
      :score => average_score || 100
    )
  end

  def show_control_objective_final_weaknesses_report_links(data, period)
    if data['weaknesses_count'].kind_of?(Hash)
      new_data = []
      pc = data['process_control']
      co = data['control_objective']

      @risk_levels.each do |risk|
        risk_text = t("risk_types.#{risk}")
        ids_complete = @control_objectives_data[period][pc][co][risk_text][:complete]
        ids_incomplete = @control_objectives_data[period][pc][co][risk_text][:incomplete]
        url_complete = weaknesses_path(:ids => ids_complete)
        url_incomplete = weaknesses_path(:ids => ids_incomplete)

        if ids_incomplete.blank? && ids_complete.blank?
          new_data << "#{risk_text}: 0 / 0"
        elsif ids_incomplete.present? && ids_complete.blank?
          new_data <<  "[#{risk_text}: #{ids_incomplete.count}](#{url_incomplete}) / 0"
        elsif ids_incomplete.blank? && ids_complete.present?
          new_data << "[#{risk_text}: 0 / #{ids_complete.count}](#{url_complete})"
        elsif ids_incomplete.present? & ids_complete.present?
          new_data << "#{risk_text}: [#{ids_incomplete.count}](#{url_incomplete}) / [#{ids_complete.count}](#{url_complete})"
        end
      end

      array_to_ul(new_data, class: 'list-unstyled')
    else
      data['weaknesses_count']
    end
  end

  def show_process_control_final_weaknesses_report_links(data)
    if data['weaknesses_count'].kind_of?(Array)
      new_data = []

      data['weaknesses_count'].each do |label|
        ids = @process_control_ids_data[data['process_control']][label]
        url = weaknesses_path(:ids => ids)

        new_data << (ids.blank? ? label : "[#{label}](#{url})")
      end

      array_to_ul(new_data, class: 'list-unstyled')
    else
      data['weaknesses_count']
    end
  end
end
