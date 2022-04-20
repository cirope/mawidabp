# frozen_string_literal: true

class Sector < ApplicationRecord
  include Sectors::Scopes
  include Sectors::Validation

  has_many :control_objectives
  belongs_to :organization
end
