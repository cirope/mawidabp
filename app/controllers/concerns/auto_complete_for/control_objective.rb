module AutoCompleteFor::ControlObjective
  extend ActiveSupport::Concern

  def auto_complete_for_control_objective
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}

    conditions = [
      [
        [
          "#{::BestPractice.table_name}.#{::BestPractice.qcn 'shared'} = :false",
          "#{::BestPractice.table_name}.#{::BestPractice.qcn 'organization_id'} = :organization_id"
        ].join(' AND '),
        [
          "#{::BestPractice.table_name}.#{::BestPractice.qcn 'shared'} = :true",
          "#{::BestPractice.table_name}.#{::BestPractice.qcn 'group_id'} = :group_id"
        ].join(' AND ')
      ].map { |c| "(#{c})" }.join(' OR '),
      "#{::ControlObjective.quoted_table_name}.#{::ControlObjective.qcn('obsolete')} = :false"
    ]
    parameters = {
      false:           false,
      true:            true,
      organization_id: Current.organization&.id,
      group_id:        Current.group.id
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{::ControlObjective.quoted_table_name}.#{::ControlObjective.qcn('name')}) LIKE :control_objective_data_#{i}",
        "LOWER(#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('name')}) LIKE :control_objective_data_#{i}"
      ].join(' OR ')

      parameters[:"control_objective_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @control_objectives = ::ControlObjective.includes(
      process_control: :best_practice
    ).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      [
        "#{::ProcessControl.quoted_table_name}.#{::ProcessControl.qcn('name')} ASC",
        "#{::ControlObjective.quoted_table_name}.#{::ControlObjective.qcn('order')} ASC"
      ].map { |o| Arel.sql o }
    ).references(:best_practices, :process_control).limit(10)

    respond_to do |format|
      format.json { render json: @control_objectives }
    end
  end
end
