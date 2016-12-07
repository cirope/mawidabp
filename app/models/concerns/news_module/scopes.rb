module NewsModule::Scopes
  extend ActiveSupport::Concern

  included do
    scope :published, -> {
      where "#{quoted_table_name}.#{qcn 'published_at'} <= ?", Time.zone.now.end_of_day
    }
  end
end
