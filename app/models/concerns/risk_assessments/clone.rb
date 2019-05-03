module RiskAssessments::Clone
  extend ActiveSupport::Concern

  def clone_from other
    on_same_organization = organization == other.organization
    new_attributes       = {}
    original_attributes  = attributes.dup
    other_attributes     = other.attributes.except(
      *except_attributes(on_same_organization)
    )

    original_attributes.each do |name, value|
      new_attributes[name] = value.presence || other_attributes[name]
    end

    assign_attributes new_attributes.merge('shared' => false)
    clone_risk_assessment_items_from other, on_same_organization
  end

  private

    def except_attributes on_same_organization
      common = [
        'id',
        'status',
        'period_id',
        'plan_id',
        'organization_id',
        'file_model_id',
        'shared',
        'created_at',
        'updated_at',
        'lock_version'
      ]

      if on_same_organization
        common
      else
        common << 'risk_assessment_template_id'
      end
    end

    def item_except_attributes on_same_organization
      common = [
        'id',
        'risk_assessment_id',
        'risk',
        'created_at',
        'updated_at'
      ]

      if on_same_organization
        common
      else
        common << 'business_unit_id'
      end
    end

    def clone_risk_assessment_items_from other, on_same_organization
      other.risk_assessment_items.includes(:process_control).each do |rai|
        if on_same_organization || rai.process_control&.best_practice&.shared
          attributes = rai.attributes.except(
            *item_except_attributes(on_same_organization)
          )

          clone_risk_weights_from rai,
                                  risk_assessment_items.build(attributes),
                                  on_same_organization
        end
      end
    end

    def clone_risk_weights_from rai, new_rai, on_same_organization
      if on_same_organization
        rai.risk_weights.each do |rw|
          weight_attributes = rw.attributes.except 'id',
                                                   'risk_assessment_item_id',
                                                   'value',
                                                   'created_at',
                                                   'updated_at'

          new_rai.risk_weights.build weight_attributes
        end
      elsif new_rai.risk_assessment.risk_assessment_template
        new_rai.build_risk_weights
      end
    end
end
