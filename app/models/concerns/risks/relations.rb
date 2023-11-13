module Risks::Relations
  extend ActiveSupport::Concern

  included do
    belongs_to :user
    belongs_to :risk_category, optional: true
    has_many :risk_control_objectives, dependent: :destroy
    has_many :control_objectives, through: :risk_control_objectives

    accepts_nested_attributes_for :risk_control_objectives,
      allow_destroy: true, reject_if: :all_blank
  end
end
