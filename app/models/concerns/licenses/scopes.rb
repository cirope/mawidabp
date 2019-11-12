# frozen_string_literal: true

module Licenses::Scopes
  extend ActiveSupport::Concern

  included do
    scope :past_due, -> { where "#{table_name}.paid_until < ?", Time.zone.today }
  end
end
