module Findings::Reiterations
  extend ActiveSupport::Concern

  included do
    scope :repeated,     -> { where     state: Finding::STATUS[:repeated] }
    scope :not_repeated, -> { where.not state: Finding::STATUS[:repeated] }

    scope :with_repeated,    -> { where.not repeated_of_id: nil }
    scope :without_repeated, -> { where     repeated_of_id: nil }

    before_save :check_for_reiteration

    belongs_to :repeated_of, foreign_key: 'repeated_of_id', class_name: 'Finding', autosave: true, optional: true
    has_one    :repeated_in, -> { where final: false }, foreign_key: 'repeated_of_id', class_name: 'Finding'
  end

  def undo_reiteration
    raise 'Unknown previous repeated state' if repeated_of_versions_with_state.blank?

    self.undoing_reiteration = true

    if final_review_created_at.blank? && rescheduled?
      update_column :reschedule_count, 0
    end

    repeated_of.update_column :state, previous_repeated_of_state
    update_columns repeated_of_id: nil, origination_date: Time.zone.today
  end

  def repeated_root
    node = self
    node = node.repeated_of while node.repeated_of
    node
  end

  def repeated_ancestors
    node, nodes = self, []
    nodes << node = node.repeated_of while node.repeated_of
    nodes
  end

  def repeated_children
    node, nodes = self, []
    nodes << node = node.repeated_in while node.repeated_in
    nodes
  end

  def repeated_leaf
    node = self
    node = node.repeated_in while node.repeated_in

    node
  end

  private

    def repeated_of_versions_with_state
      repeated_of.versions.select do |v|
        finding = v.reify has_one: false
        finding.try(:state) && !finding.repeated?
      end
    end

    def previous_repeated_of_state
      repeated_of_versions_with_state.last.reify(has_one: false).state
    end

    def check_for_reiteration
      if reiteration?
        raise 'Not included in review' unless review_include_repeated?
        raise 'Original finding can not be changed' if repeated_of_id_was
        raise 'Original can not be repeated' if repeated_of.repeated? && !final

        self.repeated_of.state = Finding::STATUS[:repeated]
        self.origination_date  = repeated_of.origination_date
      end
    end

    def reiteration?
      !undoing_reiteration && repeated_of_id_changed? && control_objective_item.try(:review)
    end

    def review_include_repeated?
      review = control_objective_item.try(:review)

      review.finding_review_assignments.any? do |fra|
        fra.finding_id == repeated_of_id
      end
    end
end
