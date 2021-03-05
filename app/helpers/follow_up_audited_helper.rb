module FollowUpAuditedHelper
  def show_process_control_audited_weaknesses_report(data)
    if data['weaknesses_count'].kind_of?(Array)
      new_data = []

      data['weaknesses_count'].each do |label|
        new_data << label
      end

      array_to_ul(new_data, class: 'list-unstyled')
    else
      data['weaknesses_count']
    end
  end
end
