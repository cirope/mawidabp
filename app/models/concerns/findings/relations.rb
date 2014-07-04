module Findings::Relations
  extend ActiveSupport::Concern

  included do
    has_many :finding_relations, dependent: :destroy, before_add: :check_for_valid_relation
    has_many :inverse_finding_relations, foreign_key: 'related_finding_id', class_name: 'FindingRelation'

    accepts_nested_attributes_for :finding_relations, allow_destroy: true
  end

  private

    def check_for_valid_relation finding_relation
      related_finding = finding_relation.related_finding

      raise 'Invalid finding for asociation' if invalid_related_finding? related_finding
    end

    def invalid_related_finding? related_finding
      review_id = control_objective_item.try :review_id

      related_finding &&
        (related_finding.final? ||
         (!related_finding.is_in_a_final_review? && related_finding.review.id != review_id))
    end
end
