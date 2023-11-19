module RiskAssessments::RiskAssessemntWeights
  extend ActiveSupport::Concern

  included do
    has_many :risk_assessment_weights, as: :owner, dependent: :destroy
    has_many :risk_score_items, through: :risk_assessment_weights

    after_create_commit :clone_risk_assessment_weights
  end

  private

    def clone_risk_assessment_weights
      clone_risk_assessment_weights_from = cloned_from || risk_assessment_template

      clone_risk_assessment_weights_from.risk_assessment_weights.each do |raw|
        attributes = raw.attributes.except 'id',
                                           'owner_id',
                                           'owner_type',
                                           'created_at',
                                           'updated_at',
                                           'lock_version'

        new_raw = risk_assessment_weights.new attributes

        clone_risk_score_items_from raw, new_raw

        new_raw.save!
      end

      _clone_risk_weights_from cloned_from if cloned_from
    end

    def clone_risk_score_items_from raw, new_raw
      raw.risk_score_items.each do |rsi|
        risk_score_items_attributes = rsi.attributes.except 'id',
                                                            'risk_assessment_weight_id',
                                                            'created_at',
                                                            'updated_at'

        new_raw.risk_score_items.build risk_score_items_attributes
      end
    end

    def _clone_risk_weights_from cloned_from
      raws = risk_assessment_weights.to_a

      risk_assessment_items.each do |rai|
        rai.risk_weights.each_with_index do |rw, idx|
          rw.update_column :risk_assessment_weight_id, raws[idx].id
        end
      end
    end
end
