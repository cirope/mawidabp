module RiskAssessments::CSV
  extend ActiveSupport::Concern

  def to_csv completed: 'incomplete', corporate: false
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    ::CSV.generate(options) do |csv|
      csv << csv_column_headers
      csv << csv_column_sub_headers

      risk_assessment_items.each do |risk_assessment_item|
        csv << risk_assessment_item_csv_row(risk_assessment_item)
      end
    end
  end

  private

    def csv_column_headers
      [
        RiskAssessment.model_name.human,
        name,
        description,
        RiskAssessment.human_attribute_name('risk_assessment_weights'),
        risk_assessment_weights.pluck('weight')
      ].flatten
    end

    def csv_column_sub_headers
      [
        RiskAssessmentItem.model_name.human,
        BusinessUnitType.model_name.human,
        BusinessUnit.model_name.human,
        RiskAssessmentItem.human_attribute_name('risk'),
        risk_assessment_weights.pluck('name')
      ].flatten
    end

    def risk_assessment_item_csv_row risk_assessment_item
      [
        risk_assessment_item.name,
        risk_assessment_item.business_unit_type,
        risk_assessment_item.business_unit,
        risk_assessment_item.risk,
        risk_assessment_weights.map do |risk_assessment_weight|
          risk_weight = risk_assessment_item.risk_weights.detect do |rw|
            rw.risk_assessment_weight_id == risk_assessment_weight.id
          end

          risk_weight.value
        end
      ].flatten
    end
end
