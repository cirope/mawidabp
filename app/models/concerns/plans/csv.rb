module Plans::Csv
  extend ActiveSupport::Concern

  def to_csv business_unit_type: nil, dprh: false
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }
    @dprh   = dprh

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_headers

      csv_put_business_unit_types_on csv, business_unit_type
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename
    if Current.conclusion_pdf_format == 'pat' && @dprh == true
      I18n.t 'plans.csv.csv_name_pat_dprh', current_date: Time.zone.now.strftime("%Y%m%d")
    elsif Current.conclusion_pdf_format == 'pat'
      I18n.t 'plans.csv.csv_name_pat_im', current_date: Time.zone.now.strftime("%Y%m%d")
    else
      I18n.t 'plans.csv.csv_name', period: period.name
    end
  end

  private

    def csv_headers
      headers = [
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
        (Current.conclusion_pdf_format == 'pat' ? I18n.t('plans.csv.annual_plan_hours') : PlanItem.human_attribute_name(:human_resource_units)),
        (PlanItem.human_attribute_name(:material_resource_units) unless Current.conclusion_pdf_format == 'pat'),
        (PlanItem.human_attribute_name(:total_resource_units) unless Current.conclusion_pdf_format == 'pat')
      ].compact

      headers += add_bic_headers if Current.conclusion_pdf_format == 'bic'
      headers += add_pat_headers if Current.conclusion_pdf_format == 'pat'
      headers
    end

    def add_bic_headers
      [
        Review.human_attribute_name(:score),
        I18n.t('risk_types.low'),
        I18n.t('risk_types.medium'),
        I18n.t('risk_types.high'),
        ConclusionDraftReview.human_attribute_name(:issue_date)
      ]
    end

    def add_pat_headers
      if @dprh
        [
          I18n.t('plans.csv_prh_pat.progress'),
          I18n.t('plans.csv_prh_pat.percentage')
        ]
      else
        [
          I18n.t('plans.csv.auditor'),
          I18n.t('plans.csv.time_summary_hours')
        ]
      end
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
          array_to_csv = [
            plan_item.order_number,
            Current.conclusion_pdf_format == 'pat' ? plan_item.status_text_pat(long: false).to_s : plan_item.status_text(long: false).to_s,
            business_unit_type&.name || '',
            plan_item.business_unit&.name || '',
            plan_item.project.to_s,
            (plan_item.scope.to_s if SHOW_REVIEW_EXTRA_ATTRIBUTES),
            (plan_item.risk_exposure.to_s if SHOW_REVIEW_EXTRA_ATTRIBUTES),
            plan_item.tags.map(&:to_s).join(';'),
            I18n.l(plan_item.start, format: :default),
            I18n.l(plan_item.end, format: :default),
            '%.2f' % plan_item.human_units,
            ('%.2f' % plan_item.material_units unless Current.conclusion_pdf_format == 'pat'),
            ('%.2f' % plan_item.units unless Current.conclusion_pdf_format == 'pat')
          ]

          if Current.conclusion_pdf_format == 'bic'
            observations_per_risk = number_observations_per_risk(plan_item)

            array_to_csv += [
              score_plan_item(plan_item),
              observations_per_risk[RISK_TYPES[:low]],
              observations_per_risk[RISK_TYPES[:medium]],
              observations_per_risk[RISK_TYPES[:high]],
              plan_item_issue_date(plan_item)
            ]
          end

          if Current.conclusion_pdf_format == 'pat'
            if @dprh
              array_to_csv += [
                '%.2f' % plan_item.progress.to_i,
                '%.2f' % get_percentage(plan_item.human_units.to_i, plan_item.progress.to_i),
              ]
            else
              array_to_csv += [
                plan_item_auditors(plan_item) || '',
                '%.2f' % plan_item&.human_units_consumed,
              ]
            end
          end

          csv << array_to_csv.compact
        end
      end
    end

    def plan_item_auditors plan_item
      if plan_item.review
        auditors = plan_item.review.review_user_assignments.select(&:auditor?).map(&:user)
        auditors.map { |u| u.full_name(nil, true)}.join ' - '
      end
    end

    def score_plan_item plan_item
      plan_item.review ? plan_item.review.score_text : '-'
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

      results
    end
end
