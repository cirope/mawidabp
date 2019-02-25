module RiskAssessmentTemplates::Clone
  extend ActiveSupport::Concern

  def clone_from other
    self.attributes = other.attributes.except 'id',
                                              'created_at',
                                              'updated_at',
                                              'lock_version'

    clone_risk_assessment_weights_from other
  end

  private

    def clone_risk_assessment_weights_from other
      other.risk_assessment_weights.map do |raw|
        attributes = raw.attributes.except 'id',
                                           'risk_assessment_template_id',
                                           'created_at',
                                           'updated_at'

        risk_assessment_weights.build attributes
      end
    end
end
