module ErrorRecords::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Current.organization_id) }

    scope :between, ->(conditions) {
      list.
      includes(:user).
      where(conditions).
      order(Arel.sql("#{quoted_table_name}.#{qcn('created_at')} DESC")).
      references(:users)
    }
  end
end
