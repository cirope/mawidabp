module Findings::Reiterations
  extend ActiveSupport::Concern

  DEFAULT_TO_S_PRELOADS = [
    control_objective_item: {
      review: [:plan_item, :conclusion_final_review]
    }
  ]

  included do
    scope :repeated,     -> { where     state: Finding::STATUS[:repeated] }
    scope :not_repeated, -> { where.not state: Finding::STATUS[:repeated] }

    scope :with_repeated,    -> { where.not repeated_of_id: nil }
    scope :without_repeated, -> { where     repeated_of_id: nil }

    before_save :check_for_reiteration, if: :reiteration?
    before_save :update_parent_ids, if: :update_parent_ids?
    after_save :update_latest, if: :update_latest?

    belongs_to :latest, foreign_key: 'latest_id', class_name: 'Finding', optional: true
    belongs_to :repeated_of, foreign_key: 'repeated_of_id', class_name: 'Finding', autosave: true, optional: true
    has_one    :repeated_in, -> { where final: false }, foreign_key: 'repeated_of_id', class_name: 'Finding'
  end

  def undo_reiteration
    raise 'Unknown previous repeated state' if repeated_of_versions_with_state.blank?

    self.undoing_reiteration = true

    attrs = {
      origination_date: Time.zone.today,
      parent_ids:       [],
      repeated_of_id:   nil
    }

    attrs[:reschedule_count] = 0 if final_review_created_at.blank? && rescheduled?

    repeated_of.update_column :state, previous_repeated_of_state
    repeated_of.update_latest
    update_columns attrs
  end

  def update_parent_ids?
    will_save_change_to_repeated_of_id? && repeated_of
  end

  def update_parent_ids
    self.parent_ids = repeated_of.parent_ids + [repeated_of_id]
  end

  def repeated_root
    parent_ids.any? ? Finding.unscoped.find(parent_ids.first) : self
  end

  def repeated_leaf
    Finding.unscoped.with_parent_id(id).order('array_length(parent_ids, 1) DESC').first if id
  end

  def repeated_ancestors
    if parent_ids.empty?
      self.class.none
    else
      Finding.unscoped.where(id: parent_ids).preload *DEFAULT_TO_S_PRELOADS
    end
  end

  def repeated_children
    if id
      Finding.unscoped.with_parent_id(id).preload *DEFAULT_TO_S_PRELOADS
    else
      self.class.none
    end
  end

  def update_latest
    cursor   = self
    findings = []

    while cursor.repeated_of
      findings << (cursor = cursor.repeated_of)
    end

    update_column :latest_id, nil
    findings.each { |f| f.update_column :latest_id, id }
  end

  module ClassMethods
    def with_parent_id id
      where "ARRAY[?] <@ #{table_name}.parent_ids", id
    end
  end

  private

    def repeated_of_versions_with_state
      @_repeated_of_versions_with_state ||= repeated_of.versions.select do |v|
        finding = v.reify has_one: false
        finding.try(:state) && !finding.repeated?
      end
    end

    def previous_repeated_of_state
      repeated_of_versions_with_state.last.reify(has_one: false).state
    end

    def check_for_reiteration
      raise 'Not included in review' unless review_include_repeated?
      raise 'Original finding can not be changed' if repeated_of_id_was
      raise 'Original can not be repeated' if repeated_of.repeated? && !final

      self.repeated_of.state = Finding::STATUS[:repeated]
      self.origination_date  = repeated_of.origination_date
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

    def update_latest?
      !final && saved_change_to_repeated_of_id? && repeated_of
    end
end
