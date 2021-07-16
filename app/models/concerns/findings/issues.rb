module Findings::Issues
  extend ActiveSupport::Concern

  included do
    before_validation :set_issue_based_status

    has_many :issues, -> { order id: :asc }, dependent: :destroy, inverse_of: :finding

    accepts_nested_attributes_for :issues, allow_destroy: true, reject_if: :all_blank
  end

  def issues_amount
    issues.sum &:amount
  end

  def get_amount_by_impact
    amount = issues_amount

    amount_by_impact.detect { |name, import| amount <= import }
  end

  def impact_risk_text
    I18n.t("impact_risk_types.#{Finding::IMPACT_RISKS.invert[get_amount_by_impact.first]}")
  end

  def impact_risk_value
    get_amount_by_impact.first
  end

  def probability_risk
    quantity ||= 0

    # if review.previous && weakness_previous
    #   quantity++
    # end
  end

  def weaknesses_previous
    review.previous.weaknesses.map(&:weakness_template_id).include? weakness_template_id
  end

  def amount_by_impact
    {
      1 => 2084408,
      2 => 20844081,
      3 => 208440815,
      4 => 2084408150,
      5 => 9999999999
    }
  end

  private

    def set_issue_based_status
      valid_issues = issues.reject &:marked_for_destruction?

      if valid_issues.select(&:changed?).any? && USE_SCOPE_CYCLE
        all_closed  = valid_issues.all? &:close_date
        some_closed = valid_issues.any? &:close_date

        if all_closed
          self.state         = Finding::STATUS['implemented_audited']
          self.solution_date = valid_issues.map(&:close_date).last
        elsif some_closed
          self.state            = Finding::STATUS['being_implemented']
          self.follow_up_date ||= 9.months.from_now.to_date
        elsif !some_closed && !awaiting?
          self.state          = Finding::STATUS['awaiting']
          self.follow_up_date = nil
        end
      end
    end
end
