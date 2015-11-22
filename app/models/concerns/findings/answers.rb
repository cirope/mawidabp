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
end
