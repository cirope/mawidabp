module Findings::Answers
  extend ActiveSupport::Concern

  included do
    has_many :finding_answers, -> { order created_at: :asc }, dependent: :destroy, after_add: :answer_added

    accepts_nested_attributes_for :finding_answers, allow_destroy: false,
      reject_if: ->(attributes) { attributes['answer'].blank? }
  end

  def answer_added finding_answer
    if (unconfirmed? || notify?) && finding_answer.answer.present? && finding_answer.user.try(:can_act_as_audited?)
      confirmed! finding_answer.user
    end

    self.updated_at = Time.zone.now
  end

  def last_commitment_date
    finding_answers.
      where.not(commitment_date: nil).
      reorder(commitment_date: :desc).
      first&.commitment_date
  end
end
