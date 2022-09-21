module Plans::CsvPrsPat
  extend ActiveSupport::Concern

  def to_csv_prs business_unit_type: nil
    options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

    csv_str = CSV.generate(**options) do |csv|
      csv << csv_headers_prs

      csv_put_business_unit_types_on_prs csv, business_unit_type
    end

    "\uFEFF#{csv_str}"
  end

  def csv_filename_prs
    I18n.t 'plans.csv_prs_pat.csv_name', current_date: Time.zone.now.strftime("%Y%m%d")
  end

  private

    def csv_headers_prs
      [
        I18n.t('plans.csv_prs_pat.business_unit'),
        I18n.t('plans.item_status_csv_pat.completed.long'),
        I18n.t('plans.item_status_csv_pat.completed_early.long'),
        I18n.t('plans.item_status_csv_pat.in_early_progress.long'),
        I18n.t('plans.item_status_csv_pat.not_started_no_delayed.long'),
        I18n.t('plans.item_status_csv_pat.in_progress_no_delayed.long'),
        I18n.t('plans.item_status_csv_pat.delayed_pat.long'),
        I18n.t('plans.item_status_csv_pat.overdue.long'),
        I18n.t('plans.csv_prs_pat.totals')
      ]
    end

    def csv_put_business_unit_types_on_prs csv, business_unit_type
      totals_row_data = []

      if business_unit_type
        put_csv_rows_on_prs csv, business_unit_type, totals_row_data
      else
        business_unit_types.each do |business_unit_type|
          put_csv_rows_on_prs csv, business_unit_type, totals_row_data
        end
      end

      put_totals_row_prs csv, totals_row_data
    end

    def put_csv_rows_on_prs csv, business_unit_type, totals_row_data
      plan_items = Array(grouped_plan_items[business_unit_type]).sort
      pi_status  = Hash.new(0)

      if plan_items.present?
        plan_items.each do |plan_item|
          pi_status[plan_item.check_status.to_sym] += 1
        end

        values = [
          pi_status[:completed],
          pi_status[:completed_early],
          pi_status[:in_early_progress],
          pi_status[:not_started_no_delayed],
          pi_status[:in_progress_no_delayed],
          pi_status[:delayed_pat],
          pi_status[:overdue]
        ]

        totals_row_data << values

        values.push values.sum
        values.unshift(business_unit_type&.name || '')

        csv << values
      end
    end

    def put_totals_row_prs csv, totals_row_data
      totals_row = [
        I18n.t('plans.csv_prs_pat.total_plan_items'),
        totals_row_data.transpose[1].sum,
        totals_row_data.transpose[2].sum,
        totals_row_data.transpose[3].sum,
        totals_row_data.transpose[4].sum,
        totals_row_data.transpose[5].sum,
        totals_row_data.transpose[6].sum,
        totals_row_data.transpose[7].sum,
        totals_row_data.transpose[8].sum
      ]

      csv << totals_row
    end
end
