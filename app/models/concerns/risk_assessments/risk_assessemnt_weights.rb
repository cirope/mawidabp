module RiskAssessments::RiskAssessemntWeights
  extend ActiveSupport::Concern

  included do
    has_many :risk_assessment_weights, as: :owner, dependent: :destroy
    has_many :risk_score_items, through: :risk_assessment_weights

    after_create_commit :clone_risk_assessment_weights
  end

  private

    def clone_risk_assessment_weights
      risk_assessment_template.risk_assessment_weights.each do |raw|
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
end
