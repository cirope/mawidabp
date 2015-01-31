module AutoCompleteFor::User
  extend ActiveSupport::Concern

  def auto_complete_for_user
    @tokens = params[:q][0..100].split(/[\s,]/).uniq
    @tokens.reject! {|t| t.blank?}
    conditions = [
      "#{Organization.quoted_table_name}.#{Organization.qcn('id')} = :organization_id",
      "#{User.quoted_table_name}.#{User.qcn('hidden')} = false"
    ]
    parameters = { organization_id: current_organization.id }
    @tokens.each_with_index do |t, i|
      conditions << [
        "LOWER(#{User.quoted_table_name}.#{User.qcn('name')}) LIKE :user_data_#{i}",
        "LOWER(#{User.quoted_table_name}.#{User.qcn('last_name')}) LIKE :user_data_#{i}",
        "LOWER(#{User.quoted_table_name}.#{User.qcn('function')}) LIKE :user_data_#{i}",
        "LOWER(#{User.quoted_table_name}.#{User.qcn('user')}) LIKE :user_data_#{i}"
      ].join(' OR ')

      parameters[:"user_data_#{i}"] = "%#{t.mb_chars.downcase}%"
    end

    @users = User.includes(:organizations).where(
      conditions.map { |c| "(#{c})" }.join(' AND '), parameters
    ).order([
      "#{User.quoted_table_name}.#{User.qcn('last_name')} ASC",
      "#{User.quoted_table_name}.#{User.qcn('name')} ASC"
    ]).limit(10).references(:organizations)

    respond_to do |format|
      format.json { render json: @users }
    end
  end
end
