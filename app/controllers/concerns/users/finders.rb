module Users::Finders
  extend ActiveSupport::Concern

  private

    def find_with_organization id, field = :user
      id = field == :id ? id.to_i : id.try(:downcase).try(:strip)
      quoted_field = "#{User.quoted_table_name}.#{User.qcn(field)}"
      id_field = field == :id ? quoted_field : "LOWER(#{quoted_field})"

      User.includes(:organizations).where(
        [
          "#{id_field} = :id",
          "#{User.quoted_table_name}.#{User.qcn('hidden')} = :false",
          [
            "#{Organization.quoted_table_name}.#{Organization.qcn('id')} = :organization_id",
            "#{Organization.quoted_table_name}.#{Organization.qcn('id')} IS NULL"
          ].join(' OR ')
        ].map { |c| "(#{c})" }.join(' AND '),
        { id: id, organization_id: current_organization.try(:id), false: false }
      ).references(:organizations).first || (find_with_organization(id, :id) unless field == :id)
    end

    def set_user
      @user = User.includes(:organizations).where(
        user: params[:id], organizations: { id: current_organization.try(:id) },
      ).references(:organizations).first if params[:id].present?
    end
end
