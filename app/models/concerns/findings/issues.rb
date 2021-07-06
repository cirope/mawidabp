module Findings::Issues
  extend ActiveSupport::Concern

  included do
    AMOUNT_IMPACT = amount_impact

    before_validation :set_issue_based_status

    has_many :issues, -> { order id: :asc }, dependent: :destroy, inverse_of: :finding

    accepts_nested_attributes_for :issues, allow_destroy: true, reject_if: :all_blank
  end

  module ClassMethods

    private
      def amount_impact
        {
          1 => 2084408,
          2 => 20844081,
          3 => 208440815,
          4 => 2084408150,
          5 => 9999999999
        }
      end
  end

  def impact_risk_text impact
    impact ? I18n.t("impact_risk_types.#{Finding::IMPACT_RISKS.invert[impact]}") : '-'
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
