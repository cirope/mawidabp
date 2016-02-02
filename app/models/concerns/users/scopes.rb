module Users::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      includes(:organizations).
        where(organizations: { id: Organization.current_id }).
        references :organizations
    }
    scope :not_hidden, -> { where hidden: false }
  end

  module ClassMethods
    def all_with_findings_for_notification
      includes(finding_user_assignments: :raw_finding).
        where(findings: { state: Finding::STATUS[:notify], final: false }).
        order([
          "#{quoted_table_name}.#{qcn('last_name')} ASC",
          "#{quoted_table_name}.#{qcn('name')} ASC"
        ]).
        references(:findings)
    end

    def list_with_corporate
      conditions   = [
        "#{organizations_table}.#{Organization.qcn('id')} = :organization_id",
        [
          "#{organizations_table}.#{Organization.qcn('group_id')} = :group_id",
          "#{organizations_table}.#{Organization.qcn('corporate')} = :true"
        ].join(' AND ')
      ].map { |c| "(#{c})" }.join(' OR ')

      joins(:organizations).where(conditions, corporate_list_parameters).references(:organizations).uniq
    end

    private

      def organizations_table
        Organization.quoted_table_name
      end

      def corporate_list_parameters
        organization = Organization.find Organization.current_id

        {
          organization_id: organization.id,
          group_id:        organization.group_id,
          true:            true
        }
      end
  end
end
