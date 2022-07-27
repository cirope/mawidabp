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
      progress_hours = []

      if plan_items.present?
        plan_items.each do |plan_item|
          progress_hours << plan_item.progress.to_i
          budgeted_hours << plan_item.human_units.to_i
        end

        percentage = budgeted_hours.sum == 0 ? 0.0 : (progress_hours.sum.to_f * 100 / budgeted_hours.sum.to_f).round(2)

        values = [
          business_unit_type&.name || '',
          budgeted_hours.sum,
          progress_hours.sum,
          percentage,
        ]

        totals_row_data << values
        csv << values
      end
    end

    def put_totals_row_prh csv, totals_row_data
      total_budgeted = totals_row_data.transpose[1].sum
      total_progress = totals_row_data.transpose[2].sum
      percentage = total_budgeted == 0 ? 0.0 : (total_progress.to_f * 100 / total_budgeted.to_f).round(2)

      totals_row = [
        I18n.t('plans.csv_prh_pat.total_hours'),
        total_budgeted,
        total_progress,
        percentage
      ]

      csv << totals_row
    end
end
