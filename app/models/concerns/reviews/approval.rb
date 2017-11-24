module Reviews::Approval
  extend ActiveSupport::Concern

  included do
    attr_reader   :approval_errors
    attr_accessor :can_be_approved_by_force
  end

  def must_be_approved?
    self.can_be_approved_by_force = true

    errors  = control_objective_items_errors
    errors += finding_review_assignment_errors

    errors << [Review.model_name.human, review_errors] if review_errors.present?

    (@approval_errors = errors).blank?
  end
  alias_method :is_approved?, :must_be_approved?

  def can_be_sended?
    must_be_approved? || can_be_approved_by_force
  end

  private

    def review_errors
      review_errors = []

      if control_objective_items.empty?
        review_errors << I18n.t('review.errors.without_control_objectives')
      end

      if survey.blank?
        review_errors << I18n.t('review.errors.without_survey')
      end

      unless has_audited?
        review_errors << I18n.t('review.errors.without_audited')
      end

      review_errors
    end

    def control_objective_items_errors
      errors = []

      control_objective_items.each do |control_objective_item|
        errors += weakness_errors control_objective_item
        errors += oportunity_errors control_objective_item
        errors += control_objective_item_errors control_objective_item
      end

      errors
    end

    def weakness_errors control_objective_item
      errors = []

      control_objective_item.weaknesses.each do |w|
        unless w.must_be_approved?
          self.can_be_approved_by_force = false

          errors << [
            "#{Weakness.model_name.human} #{w.review_code} - #{w.title}",
            w.approval_errors
          ]
        end
      end

      errors + unconfirmed_weaknesses_errors(control_objective_item)
    end

    def unconfirmed_weaknesses_errors control_objective_item
      control_objective_item.weaknesses.select(&:unconfirmed?).map do |w|
        [
          "#{Weakness.model_name.human} #{w.review_code} - #{w.title}",
          [I18n.t('weakness.errors.is_unconfirmed')]
        ]
      end
    end

    def oportunity_errors control_objective_item
      errors = []

      control_objective_item.oportunities.each do |o|
        unless o.must_be_approved?
          errors << [
            "#{Oportunity.model_name.human} #{o.review_code} - #{o.title}",
            o.approval_errors
          ]
        end
      end

      errors
    end

    def control_objective_item_errors control_objective_item
      errors = []

      unless control_objective_item.must_be_approved?
        self.can_be_approved_by_force = false

        errors << [
          "#{ControlObjectiveItem.model_name.human}: #{control_objective_item}",
          control_objective_item.approval_errors
        ]
      end

      errors
    end

    def finding_review_assignment_errors
      errors = []

      finding_review_assignments.each do |fra|
        finding = fra.finding

        if !finding.repeated? && !finding.implemented_audited?
          finding_label  = "#{Finding.model_name.human} #{finding.review_code}"
          finding_label += " - #{finding.title} [#{finding.review}]"

          errors << [
            finding_label,
            [I18n.t('review.errors.related_finding_incomplete')]
          ]
        end
      end

      errors
    end
end
