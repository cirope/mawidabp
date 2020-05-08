class CommitmentSupport < ApplicationRecord
  include Auditable
  include CommitmentSupports::Validation

  belongs_to :finding_answer
end
