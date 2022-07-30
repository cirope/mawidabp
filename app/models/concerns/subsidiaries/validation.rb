# frozen_string_literal: true

module Subsidiaries::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
    validates :identity, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  end
end
