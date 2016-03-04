module AutoCompleteFor::ProcessControl
  extend ActiveSupport::Concern

  def auto_complete_for_process_control
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    best_practice_conditions = BestPractice.list_conditions

    conditions = [
      best_practice_conditions.first,
      "#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('obsolete')} = :false"
    ]
    parameters = best_practice_conditions.last.merge(false: false)

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{BestPractice.quoted_table_name}.#{BestPractice.qcn('name')}) LIKE :process_control_data_#{i}",
        "LOWER(#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('name')}) LIKE :process_control_data_#{i}"
      ].join(' OR ')

      parameters[:"process_control_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @process_control = ::ProcessControl.includes(
      :best_practice
    ).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      "#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('name')} ASC"
    ).references(:best_practice).limit(10)

    respond_to do |format|
      format.json { render json: @process_control }
    end
  end
end
