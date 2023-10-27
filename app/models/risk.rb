class Risk < ApplicationRecord
  include Risks::I18nRiskHelpers
  include Risks::Relations
  include Risks::Validation

  scope :ordered, -> { order name: :asc }

  def to_s
    name
  end
end
