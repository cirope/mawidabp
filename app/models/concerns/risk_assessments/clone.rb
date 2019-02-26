module RiskAssessments::Clone
  extend ActiveSupport::Concern

  def clone_from other
    new_attributes      = {}
    original_attributes = attributes.dup
    other_attributes    = other.attributes.except 'id',
                                                  'status',
                                                  'period_id',
                                                  'plan_id',
                                                  'organization_id',
                                                  'file_model_id',
                                                  'created_at',
                                                  'updated_at',
                                                  'lock_version'

    original_attributes.each do |name, value|
      new_attributes[name] = value.presence || other_attributes[name]
    end

    assign_attributes new_attributes
    clone_risk_assessment_items_from other
  end

  private

    def clone_risk_assessment_items_from other
      other.risk_assessment_items.each do |rai|
        attributes = rai.attributes.except 'id',
                                           'risk_assessment_id',
                                           'risk',
                                           'created_at',
                                           'updated_at'

        clone_risk_weights_from rai, risk_assessment_items.build(attributes)
      end
    end

    def clone_risk_weights_from rai, new_rai
      rai.risk_weights.each do |rw|
        weight_attributes = rw.attributes.except 'id',
                                                 'risk_assessment_item_id',
                                                 'value',
                                                 'created_at',
                                                 'updated_at'

        new_rai.risk_weights.build weight_attributes
      end
    end
end
