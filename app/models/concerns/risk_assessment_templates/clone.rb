module RiskAssessmentTemplates::Clone
  extend ActiveSupport::Concern

  def clone_from other
    assign_attributes other.attributes.except 'id',
                                              'created_at',
                                              'updated_at',
                                              'lock_version'

    clone_risk_assessment_weights_from other
  end

  private

    def clone_risk_assessment_weights_from other
      other.risk_assessment_weights.each do |raw|
        attributes = raw.attributes.except 'id',
                                           'owner_type',
                                           'owner_id',
                                           'created_at',
                                           'updated_at'

        risk_assessment_weights.build attributes
      end
    end
end
