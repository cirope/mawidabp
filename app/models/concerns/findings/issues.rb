module Findings::Issues
  extend ActiveSupport::Concern

  included do
    before_validation :set_issue_based_status

    has_many :issues, -> { order id: :asc }, dependent: :destroy, inverse_of: :finding

    accepts_nested_attributes_for :issues, allow_destroy: true, reject_if: :all_blank
  end

  SUGGESTED_IMPACT_RISK_TYPES = {
    absolute_value: 1,
    representativeness: 2
  }

  SUGGESTED_PROBABILITIES_TYPES = {
    repeatability: 1,
    representativeness: 2
  }

  def issues_amount
    issues.sum &:amount
  end

  def issues_percentage
     impact_amount? ? issues.sum(&:amount) / impact_amount.to_f : 0
  end

  def get_amount_by_impact
    amount = issues_amount

    amount_by_impact.reverse_each.to_h.detect { |id, value| amount >= value }
  end

  def get_percentage_by_impact
    percentage = issues_percentage

    percentage_by_impact.reverse_each.to_h.detect { |id, value| percentage >= value }
  end

  def impact_risk_text
    I18n.t "impact_risk_types.#{Finding::IMPACT_RISKS.invert[get_amount_by_impact.first]}"
  end

  def impact_risk_value
    get_amount_by_impact&.first
  end

  def impact_risk_percentage
    get_percentage_by_impact&.first
  end

  def probability_risk_previous
    quantity = 0

    if weakness_template_id
      quantity       = 1
      current_review = review

      4.times do
        current_review = current_review&.previous

        if review && previous_weakness_by_template?(current_review)
          quantity += 1
        end
      end

      quantity = csv_base quantity if FINDING_REPEATABILITY_FILE.include? current.organization.prefix
    end

    quantity
  end

  def csv_base quantity
    csv_options = { headers: true }
    file        = FINDING_REPEATABILITY_FILE[current.organization.prefix]
    suc_id      = /\((\d+)\)/.match(review.plan_item.project)[1]

    CSV.foreach(file, csv_options) do |row|
      if row['id_ofinal'] == weakness_template.reference && row['id_suc'] == suc_id
        (1..4).each do |idx|
          quantity += (row["count#{idx}"] == '1' && quantity <= 5) ? 1 : 0
        end
      end
    end

    quantity
  end

  def get_percentage_by_probability
    percentage = issues_percentage_by_probability

    percentage_by_probability.reverse_each.to_h.detect { |id, value| percentage >= value }
  end

  def issues_percentage_by_probability
    probability_amount? ? (issues.count / probability_amount) : 0
  end

  def probability_risks_representativeness
    get_percentage_by_probability&.first
  end

  def previous_weakness_by_template? review
    Array(review&.weaknesses).map(&:weakness_template_id).include? weakness_template_id
  end

  def amount_by_impact
    {
      1 => 0,
      2 => 2084408,
      3 => 20844081,
      4 => 208440815,
      5 => 2084408150
    }
  end

  def percentage_by_impact
    {
      1 => 0,
      2 => 0.2,
      3 => 0.4,
      4 => 0.6,
      5 => 0.8,
    }
  end

  def percentage_by_probability
    {
      1 => 0,
      2 => 0.2,
      3 => 0.4,
      4 => 0.6,
      5 => 0.8,
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
          self.state = Finding::STATUS['awaiting']

          if USE_SCOPE_CYCLE
            self.follow_up_date ||= 9.months.from_now.to_date
          else
            self.follow_up_date = nil
          end
        end
      end
    end
end
