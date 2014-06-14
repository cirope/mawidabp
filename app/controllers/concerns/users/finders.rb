module Users::Finders
  extend ActiveSupport::Concern

  private

    def find_with_organization id, field = :user
      id = field == :id ? id.to_i : id.try(:downcase).try(:strip)
      id_field = field == :id ? "#{User.table_name}.#{field}" : "LOWER(#{User.table_name}.#{field})"

      User.includes(:organizations).where(
        [
          "#{id_field} = :id",
          "#{User.table_name}.hidden = :false",
          [
            "#{Organization.table_name}.id = :organization_id",
            "#{Organization.table_name}.id IS NULL"
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
