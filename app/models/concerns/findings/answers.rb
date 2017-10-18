module Findings::Answers
  extend ActiveSupport::Concern

  included do
    has_many :finding_answers, -> { order created_at: :asc }, dependent: :destroy, after_add: :answer_added

    accepts_nested_attributes_for :finding_answers, allow_destroy: false,
      reject_if: ->(attributes) { attributes['answer'].blank? }
  end

  def answer_added finding_answer
    has_audited_answer = finding_answer.answer.present? &&
                         finding_answer.user&.can_act_as_audited?

    if (unconfirmed? || notify?) && has_audited_answer
      confirmed! finding_answer.user
    end

    if has_audited_answer
      self.current_situation          = finding_answer.answer
      self.current_situation_verified = false
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
