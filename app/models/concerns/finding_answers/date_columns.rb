module FindingAnswers::DateColumns
  extend ActiveSupport::Concern

  included do
    attribute :commitment_date, :date
  end
end
