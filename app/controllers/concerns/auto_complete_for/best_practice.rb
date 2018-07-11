module AutoCompleteFor::BestPractice
  extend ActiveSupport::Concern

  def auto_complete_for_best_practice
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
      "#{::BestPractice.quoted_table_name}.#{::BestPractice.qcn('obsolete')} = :false"
    ]
    parameters = {
      false:           false,
      true:            true,
      organization_id: Organization.current_id,
      group_id:        Group.current_id
    }

    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{::BestPractice.quoted_table_name}.#{::BestPractice.qcn('name')}) LIKE :best_practice_data_#{i}",
      ].join(' OR ')

      parameters[:"best_practice_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @best_practice = ::BestPractice.where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order(
      Arel.sql("#{::BestPractice.quoted_table_name}.#{::BestPractice.qcn('name')} ASC")
    ).limit(10)

    respond_to do |format|
      format.json { render json: @best_practice }
    end
  end
end
