module FindingAnswers::Validations
  extend ActiveSupport::Concern

  included do
    validates :finding_id, :answer, presence: true
    validates :answer, pdf_encoding: true
    validates :commitment_date, timeliness: { type: :date }, allow_blank: true
    validates :commitment_date, presence: true, if: :commitment_date_should_be_present?
  end

  private

    def commitment_date_should_be_present?
      user&.can_act_as_audited? &&
        requires_commitment_date? &&
        Current.organization &&
        !Current.organization.corporate?
    end
end
