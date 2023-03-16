# frozen_string_literal: true

module Sectors::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true
  end
end
