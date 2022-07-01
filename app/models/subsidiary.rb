# frozen_string_literal: true

class Subsidiary < ApplicationRecord
  include Subsidiaries::Scopes
  include Subsidiaries::Validation

  belongs_to :organization

  def to_s
    "#{name} (#{identity})"
  end
end
