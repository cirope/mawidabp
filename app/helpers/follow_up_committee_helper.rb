module FollowUpCommitteeHelper
  def weighted_average(data)
    result = []

    if data.kind_of?(Hash)
      data.each { |_, v| result << weighted_average(v) }
    elsif data.kind_of?(Array)
      total_count = data.inject(0) { |t, n| t + n[1] }
      result << data.inject(0) { |t, n| t + n[0] * n[1] } / total_count
    end

    result.inject { |t, n| t + n } / result.size
  end

  def prepare_risk_levels(all_risks)
    risks = []

    all_risks.each do |risk_model|
      risk_model.value.each do |risk|
        cleaned_risk = [risk[0], risk[1].to_i]

        risks << cleaned_risk unless risks.include?(cleaned_risk)
      end
    end

    risks
  end

  def show_control_objective_weaknesses_report_links(data, period)
    if data['weaknesses_count'].kind_of?(Hash)
      new_data = []
      pc = data['process_control']
      co = data['control_objective']

      @risk_levels.each do |risk|
        ids_complete = @control_objectives_data[period][pc][co][risk][:complete]
        ids_incomplete = @control_objectives_data[period][pc][co][risk][:incomplete]
        url_complete = findings_path(:complete, :ids => ids_complete)
        url_incomplete = findings_path(:incomplete, :ids => ids_incomplete)

        if ids_incomplete.blank? && ids_complete.blank?
          new_data << "#{risk}: 0 / 0"
        elsif ids_incomplete.present? && ids_complete.blank?
          new_data <<  "\"#{risk}: #{ids_incomplete.count}\":#{url_incomplete} / 0"
        elsif ids_incomplete.blank? && ids_complete.present?
          new_data << "[\"#{risk}: 0 / #{ids_complete.count}\":#{url_complete}]"
        elsif ids_incomplete.present? & ids_complete.present?
          new_data << "#{risk}: \"#{ids_incomplete.count}\":#{url_incomplete} / \"#{ids_complete.count}\":#{url_complete}"
        end
      end

      array_to_ul(new_data, :class => :raw_list)
    else
      data['weaknesses_count']
    end
  end

  def show_process_control_weaknesses_report_links(data)
    if data['weaknesses_count'].kind_of?(Array)
      new_data = []

      data['weaknesses_count'].each do |label|
        ids = @process_control_ids_data[data['process_control']][label]
        url = findings_path('incomplete', :ids => ids)

        new_data << (ids.blank? ? label : "[\"#{label}\":#{url}]")
      end

      array_to_ul(new_data, :class => :raw_list)
    else
      data['weaknesses_count']
    end
  end
end
