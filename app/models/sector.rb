# frozen_string_literal: true

class Sector < ApplicationRecord
  include Sectors::Scopes
  include Sectors::Validation

  belongs_to :organization
end
