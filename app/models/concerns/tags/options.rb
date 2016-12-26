module Tags::Options
  extend ActiveSupport::Concern

  included do
    serialize :options, JSON unless connection.adapter_name == 'PostgreSQL'
  end
end
