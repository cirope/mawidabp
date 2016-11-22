module News::Scopes
  extend ActiveSupport::Concern

  included do
    scope :published, -> {
      where "#{quoted_table_name}.#{qcn 'published_at'} <= ?", Time.zone.now
    }
  end
end
