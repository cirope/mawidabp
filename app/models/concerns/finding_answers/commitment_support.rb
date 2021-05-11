module FindingAnswers::CommitmentSupport
  extend ActiveSupport::Concern

  included do
    has_one :commitment_support, dependent: :destroy

    accepts_nested_attributes_for :commitment_support, allow_destroy: false, reject_if: :skip_commitment_support
  end
end
