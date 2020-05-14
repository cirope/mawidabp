module FindingAnswers::CommitmentSupport
  extend ActiveSupport::Concern

  included do
    has_one :commitment_support, dependent: :destroy

    accepts_nested_attributes_for :commitment_support, allow_destroy: false
  end
end
