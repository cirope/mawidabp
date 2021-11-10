module FindingAnswers::Validations
  extend ActiveSupport::Concern

  included do
    validates :answer, presence: true
    validates :finding, :answer, presence: true
    validates :answer, pdf_encoding: true
    validates :commitment_date, timeliness: { type: :date }, allow_blank: true
    validates :commitment_date, presence: true, if: :commitment_date_should_be_present?
    validates :commitment_date, timeliness: {
      type: :date, on_or_before: :max_commitment_date
    }, allow_blank: true, if: :commitment_date_should_be_limited?
  end

  private

    def commitment_date_should_be_present?
      user&.can_act_as_audited? &&
        requires_commitment_date? &&
        !skip_commitment_support &&
        Current.organization &&
        !Current.organization.corporate?
    end

    def commitment_date_should_be_limited?
      FINDING_ANSWER_COMMITMENT_DATE_LIMITS.present?
    end

    def max_commitment_date
      risk  = Finding.risks.invert[finding.risk]
      limit = FINDING_ANSWER_COMMITMENT_DATE_LIMITS[
        if finding.users_that_can_act_as_audited.count > 1
          "#{risk}_multi_responsible"
        else
          risk
        end
      ]

      limit.present? ? eval(limit).from_now : 10.years.from_now
    end
end
