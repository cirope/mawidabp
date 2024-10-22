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
      reorder(created_at: :desc).
      first&.commitment_date
  end

  def commitment_date_required_level date = nil
    date ||= last_commitment_date

    if date && first_follow_up_date
      requirements = Array(commitment_requirements[self.class.risks.invert[risk]])
      required     = requirements.detect do |month_number, level|
        if first_follow_up_date.at_end_of_month == first_follow_up_date
          date <= (first_follow_up_date + month_number.months).at_end_of_month
        else
          date <= (first_follow_up_date + month_number.months)
        end
      end

      required&.last || :committee
    end
  end

  def commitment_requirements
    requirements = JSON.parse ENV['COMMITMENT_REQUIREMENTS'] || '{}'
    results      = {}

    requirements.each do |key, value|
      results[key.to_sym] = requirements[key].transform_keys(&:to_i).transform_values &:to_sym
    end

    COMMITMENT_REQUIREMENTS.merge results
  end

  def commitment_date_required_level_text date = nil
    level = commitment_date_required_level date

    I18n.t "finding.commitment_date_required_level.#{level}" if level
  end

  def commitment_date_message_for commitment_date
    limits  = COMMITMENT_DATE_LIMITS
    message = nil

    if limits.present?
        name_risk = RISK_TYPES.key(risk).to_s

      if follow_up_date.blank?
        if (date_limits = limits['first_date'])
          message = commitment_message_for date_limits[name_risk] || date_limits['default'], commitment_date
        end
      else
        if (date_limits = limits['reschedule'])
          message = commitment_message_for date_limits[name_risk] || date_limits['default'], commitment_date
        end
      end
    end

    message
  end

  private

    def commitment_message_for rules, commitment_date
      result = nil

      Array(rules).each do |limit, message|
        result = message if commitment_date > eval(limit).from_now.to_date
      end

      result
    end
end
