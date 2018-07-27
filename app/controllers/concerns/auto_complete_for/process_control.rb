module AutoCompleteFor::ProcessControl
  extend ActiveSupport::Concern

  def auto_complete_for_process_control
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}

    conditions = [
      [
        [
          "#{BestPractice.table_name}.#{BestPractice.qcn 'shared'} = :false",
          "#{BestPractice.table_name}.#{BestPractice.qcn 'organization_id'} = :organization_id"
        ].join(' AND '),
        [
          "#{BestPractice.table_name}.#{BestPractice.qcn 'shared'} = :true",
          "#{BestPractice.table_name}.#{BestPractice.qcn 'group_id'} = :group_id"
        ].join(' AND ')
      ].map { |c| "(#{c})" }.join(' OR '),
      "#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('obsolete')} = :false"
    ]
    parameters = {
      false:           false,
      true:            true,
      organization_id: Organization.current_id,
      group_id:        Group.current_id
    }

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
      Arel.sql "#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('name')} ASC"
    ).references(:best_practice).limit(10)

    respond_to do |format|
      format.json { render json: @process_control }
    end
  end
end
