module FindingAnswers::AttributeTypes
  extend ActiveSupport::Concern

  included do
    attribute :commitment_date, :date
  end
end
