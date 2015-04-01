module ErrorRecords::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Organization.current_id) }

    scope :between, ->(conditions) {
      list.
      includes(:user).
      where(conditions).
      order("#{quoted_table_name}.#{qcn('created_at')} DESC").
      references(:users)
    }
  end
end
