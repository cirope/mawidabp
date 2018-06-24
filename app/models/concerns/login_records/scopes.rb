module LoginRecords::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where(organization_id: Current.organization_id) }

    scope :between, ->(conditions) {
      list.
      includes(:user).
      where(conditions).
      order(Arel.sql("#{quoted_table_name}.#{qcn('start')} DESC")).
      references(:users)
    }
  end

  def end!
    update_column :end, Time.zone.now
  end
end
