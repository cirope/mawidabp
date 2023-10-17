module Reports::ExportIssues
  extend ActiveSupport::Concern

  def export_issues
    @title = "#{Issue.model_name.human count: 0}.csv"

    respond_to do |format|
      format.html
      format.csv do
        render csv: export_issues_csv, filename: @title.downcase
      end
    end

  end

  private

    def export_issues_csv
      options = { col_sep: ',', force_quotes: true, encoding: 'UTF-8' }

      csv_str = CSV.generate(**options) do |csv|
        csv << header_issues

        issue_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def header_issues
      [
        Issue.human_attribute_name('id'),
        Finding.human_attribute_name('review_code'),
        Issue.human_attribute_name('customer'),
        Issue.human_attribute_name('entry'),
        Issue.human_attribute_name('operation'),
        Issue.human_attribute_name('amount'),
        Issue.human_attribute_name('comments'),
        Issue.human_attribute_name('close_date'),
        Issue.human_attribute_name('currentcy')
      ]
    end

    def issue_rows
      findings = Finding.includes(:issues).list.where final: false

      findings.find_each.flat_map do |finding|
        finding.issues.map do |issue|
         [
            issue.id,
            finding.review_code,
            issue.customer,
            issue.entry,
            issue.operation,
            issue.amount,
            issue.comments,
            issue.close_date,
            issue.currency
          ]
        end
      end
    end
end
