module Findings::Answers
  extend ActiveSupport::Concern

  COMMITMENT_REQUIREMENTS = {
    high: {
      3    => :manager,
      6    => :management,
      12   => :ceo,
      1000 => :committee
    },

    medium: {
      4    => :manager,
      9    => :management,
      18   => :ceo,
      1000 => :committee
    },

    low: {
      6    => :manager,
      18   => :management,
      1000 => :management
    }
  }

  included do
    has_many :finding_answers, -> { order created_at: :asc }, dependent: :destroy, after_add: :answer_added
    has_one :latest_answer, -> { order created_at: :desc }, class_name: 'FindingAnswer'

    accepts_nested_attributes_for :finding_answers, allow_destroy: false,
      reject_if: ->(attributes) {
        attributes['endorsements_attributes'].blank? &&
        attributes['answer'].blank? &&
        attributes['commitment_date'].blank?
      }
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

  def commitment_date_required_level
    date = last_commitment_date

    if date
      requirements = Array(COMMITMENT_REQUIREMENTS[self.class.risks.invert[risk]])
      required     = requirements.detect do |month_number, level|
        date < (follow_up_date + month_number.months)
      end

      required&.last || :committee
    end
  end

  def commitment_date_required_level_text
    level = commitment_date_required_level

    I18n.t "finding.commitment_date_required_level.#{level}" if level
  end
end
