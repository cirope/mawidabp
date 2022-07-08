module Plans::CsvPrhPat
  extend ActiveSupport::Concern

  def to_csv_prh business_unit_type: nil
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_headers_prh

      csv_put_business_unit_types_on_prh csv, business_unit_type
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename_prh
    I18n.t 'plans.csv_prh_pat.csv_name', current_date: Time.zone.now.strftime("%Y%m%d")
  end

  private

    def csv_headers_prh
      [
        I18n.t('plans.csv_prh_pat.business_unit'),
        I18n.t('plans.csv_prh_pat.budgeted_hours'),
        I18n.t('plans.csv_prh_pat.progress'),
        I18n.t('plans.csv_prh_pat.percentage')
      ]
    end

    def csv_put_business_unit_types_on_prh csv, business_unit_type
      totals_row_data = []

      if business_unit_type
        put_csv_rows_on_prh csv, business_unit_type, totals_row_data
      else
        business_unit_types.each do |business_unit_type|
          put_csv_rows_on_prh csv, business_unit_type, totals_row_data
        end
      end

      put_totals_row_prh csv, totals_row_data
    end

    def put_csv_rows_on_prh csv, business_unit_type, totals_row_data
      plan_items     = Array(grouped_plan_items[business_unit_type]).sort
      budgeted_hours = []
      progress       = []

      if plan_items.present?
        plan_items.each do |plan_item|

          budgeted_hours << plan_item.human_units.to_i
          progress << plan_item.review&.time_consumptions&.sum(&:amount).to_i

        end

        percentage = budgeted_hours.sum == 0 ? 0.0 : (progress.sum.to_f * 100 / budgeted_hours.sum.to_f).round(2)
        values = [
          business_unit_type&.name || '',
          budgeted_hours.sum,
          progress.sum,
          percentage,
        ]

        totals_row_data <<  values
        csv << values
      end
    end

    def put_totals_row_prh csv, totals_row_data
      totals_row = [
        I18n.t('plans.csv_prh_pat.total_hours'),
        totals_row_data.transpose[1].sum,
        totals_row_data.transpose[2].sum,
        totals_row_data.transpose[3].sum
      ]

      csv << totals_row
    end
end
