# frozen_string_literal: true

module Reviews::Subsidiary
  extend ActiveSupport::Concern

  included do
    belongs_to :subsidiary, optional: true
  end
end
