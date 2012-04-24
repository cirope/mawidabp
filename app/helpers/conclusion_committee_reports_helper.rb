module ConclusionCommitteeReportsHelper
  def synthesis_report_score_average(title, scores)
    unless scores.blank?
      raw("<strong>#{title}</strong>: <em>#{(scores.sum.to_f / scores.size).round}%</em>")
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
        scores = data[:review_scores]

        if scores.blank?
          sum
        else
          count += 1
          sum + (scores.sum.to_f / scores.size).round
        end
      end

      average_score = count > 0 ? (total.to_f / count).round : 100
    end

    t(
      'conclusion_committee_report.synthesis_report.organization_score',
      :score => average_score || 100
    )
  end
  
  def show_control_objective_final_weaknesses_report_links(data)
    if data['weaknesses_count'].kind_of?(Array)
      new_data = []
      
      data['weaknesses_count'].each do |label|
        ids = @control_objectives_data[data['control_objective']][label]
        url = weaknesses_path(:ids => ids)
        
        new_data << (ids.blank? ? label : "[\"#{label}\":#{url}]")
      end
      
      array_to_ul(new_data, :class => :raw_list)
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
        
        new_data << (ids.blank? ? label : "[\"#{label}\":#{url}]")
      end
      
      array_to_ul(new_data, :class => :raw_list)
    else
      data['weaknesses_count']
    end
  end
end
