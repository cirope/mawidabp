module ControlObjectiveItems::BusinessUnitScores
  extend ActiveSupport::Concern

  included do
    has_many :business_unit_scores, dependent: :destroy
    has_many :business_units, through: :business_unit_scores

    accepts_nested_attributes_for :business_unit_scores, allow_destroy: true, reject_if: :all_blank
  end

  def business_unit_type_ids= ids
    Array(ids).uniq.each do |but_id|
      if BusinessUnitType.exists? but_id
        but = BusinessUnitType.find but_id

        but.business_units.each { |bu| add_business_unit_score_from bu }
      end
    end
  end

  private

    def add_business_unit_score_from bu
      business_unit_scores_ids = business_unit_scores.map &:business_unit_id
      is_not_included          = business_unit_scores_ids.exclude? bu.id
      default_score            = SHOW_SHORT_QUALIFICATIONS ?
                                   ::QUALIFICATION_TYPES[:no] :
                                   ::QUALIFICATION_TYPES[:excellent]

      if is_not_included
        business_unit_scores.build business_unit_id: bu.id,
                                   compliance_score: default_score
      end
    end
end
