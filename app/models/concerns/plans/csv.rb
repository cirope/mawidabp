module Plans::Csv
  extend ActiveSupport::Concern

  def to_csv business_unit_type: nil
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_headers

      csv_put_business_unit_types_on csv, business_unit_type
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename
    I18n.t 'plans.csv.csv_name', period: period.name
  end

  private

    def csv_headers
      [
        PlanItem.human_attribute_name(:order_number),
        PlanItem.human_attribute_name(:status),
        BusinessUnitType.model_name.human,
        PlanItem.human_attribute_name(:business_unit_id),
        PlanItem.human_attribute_name(:project),
        (PlanItem.human_attribute_name(:scope) if SHOW_REVIEW_EXTRA_ATTRIBUTES),
        (PlanItem.human_attribute_name(:risk_exposure) if SHOW_REVIEW_EXTRA_ATTRIBUTES),
        PlanItem.human_attribute_name(:tags),
        PlanItem.human_attribute_name(:start),
        PlanItem.human_attribute_name(:end),
        PlanItem.human_attribute_name(:human_resource_units),
        PlanItem.human_attribute_name(:material_resource_units),
        PlanItem.human_attribute_name(:total_resource_units),
        (Review.human_attribute_name(:score) if Current.conclusion_pdf_format == 'bic'),
        (I18n.t('plans.csv.number_observations_per_risk') if Current.conclusion_pdf_format == 'bic'),
        (ConclusionDraftReview.human_attribute_name(:issue_date) if Current.conclusion_pdf_format == 'bic')
      ].compact
    end

    def csv_put_business_unit_types_on csv, business_unit_type
      if business_unit_type
        put_csv_rows_on csv, business_unit_type
      else
        business_unit_types.each do |business_unit_type|
          put_csv_rows_on csv, business_unit_type
        end
      end
    end

    def put_csv_rows_on csv, business_unit_type
      plan_items = Array(grouped_plan_items[business_unit_type]).sort

      if plan_items.present?
        plan_items.each do |plan_item|
          csv << [
            plan_item.order_number,
            plan_item.status_text(long: false),
            business_unit_type&.name || '',
            plan_item.business_unit&.name || '',
            plan_item.project.to_s,
            (plan_item.scope.to_s if SHOW_REVIEW_EXTRA_ATTRIBUTES),
            (plan_item.risk_exposure.to_s if SHOW_REVIEW_EXTRA_ATTRIBUTES),
            plan_item.tags.map(&:to_s).join(';'),
            I18n.l(plan_item.start, format: :default),
            I18n.l(plan_item.end, format: :default),
            '%.2f' % plan_item.human_units,
            '%.2f' % plan_item.material_units,
            '%.2f' % plan_item.units,
            (score_plan_item(plan_item) if Current.conclusion_pdf_format == 'bic'),
            (number_observations_per_risk(plan_item) if Current.conclusion_pdf_format == 'bic'),
            (plan_item_issue_date(plan_item) if Current.conclusion_pdf_format == 'bic')
          ].compact
        end
      end
    end

    def score_plan_item plan_item
      plan_item.review ? "#{plan_item.review.score}%" : '-'
    end

    def plan_item_issue_date plan_item
      if plan_item.review&.conclusion_final_review
        I18n.l(plan_item.review.conclusion_final_review.issue_date, format: :minimal)
      else
        '-'
      end
    end

    def number_observations_per_risk plan_item
      results = RISK_TYPES.each_with_object({}) { |risk, hsh| hsh[risk.second] = 0 }

      if plan_item.review
        results = results.merge(plan_item.review.weaknesses.group(:risk).count)
      end

      results.map { |k, v| "#{I18n.t("risk_types.#{RISK_TYPES.key(k)}")}: #{v}" }
             .join(';')
    end
end
