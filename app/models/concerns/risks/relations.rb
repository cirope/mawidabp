module Risks::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    belongs_to :risk_category, optional: true
  end
end
