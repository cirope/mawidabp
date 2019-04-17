module Tags::Options
  extend ActiveSupport::Concern

  included do
    serialize :options, JSON unless POSTGRESQL_ADAPTER
  end
end
