module Reports::WeaknessesBrief
  extend ActiveSupport::Concern

  include ActionView::Helpers::TextHelper
  include Reports::PDF
  include Reports::Period

  def weaknesses_brief
    init_weaknesses_brief_vars

    respond_to do |format|
      format.html
      format.csv do
        render csv: weaknesses_brief_csv, filename: @title.downcase
      end
    end
  end

  def create_weaknesses_brief
    pdf_options = if PDF_LOGO_FACTOR < 1.0
                    { margins: [20, 5, 20, 5] }
                  else
                    { margins: [25, 5, 25, 5] }
                  end

    init_weaknesses_brief_vars

    pdf = init_pdf params[:report_title], params[:report_subtitle],
      options: pdf_options

    add_weaknesses_brief pdf

    add_pdf_filters pdf, @controller, @filters if @filters.present?

    save_pdf pdf, @controller, @from_date, @to_date, 'weaknesses_brief'
    redirect_to_pdf @controller, @from_date, @to_date, 'weaknesses_brief'
  end

  private

    def init_weaknesses_brief_vars
      @controller = params[:controller_name]
      @title = t("#{@controller}_committee_report.weaknesses_brief_title")
      @from_date, @to_date = *make_date_range(params[:weaknesses_brief])
      @cut_date = extract_cut_date params[:weaknesses_brief]
      @filters = []
      final = params[:final] == 'true'

      pending_weaknesses = Weakness.
        awaiting.
        or(Weakness.being_implemented).
        or(Weakness.implemented).
        finals(final).
        list_with_final_review.
        by_origination_date('BETWEEN', @from_date, @to_date)

      implemented_audited_weaknesses = Weakness.
        implemented_audited.
        finals(final).
        list_with_final_review.
        by_origination_date('BETWEEN', @from_date, @to_date).
        where solution_date: @to_date..Time.zone.today

      repeated_without_final_review = Weakness.
        list_without_final_review.
        with_repeated.
        finals(final).
        by_origination_date('BETWEEN', @from_date, @to_date)

      weaknesses = pending_weaknesses.
        or(implemented_audited_weaknesses).
        or(repeated_without_final_review).
        includes(review: [:conclusion_final_review, :plan_item]).
        preload(finding_user_assignments: :user)

      if params[:weaknesses_brief] && params[:weaknesses_brief][:user_id].present?
        user                           = User.find params[:weaknesses_brief][:user_id]
        inverted                       = params[:weaknesses_brief][:user_inverted] == '1'
        method                         = inverted ? :excluding_user_id : :by_user_id
        weaknesses                     = weaknesses.send method, user.id
        implemented_audited_weaknesses = implemented_audited_weaknesses.send method, user.id

        @filters << "<b>#{User.model_name.human}</b> #{inverted ? '!=' : '='} #{user.full_name}"
      end

      @weaknesses                     = weaknesses.reorder weaknesses_brief_order
      @implemented_audited_weaknesses = implemented_audited_weaknesses
    end

    def weaknesses_brief_csv
      options = { col_sep: ';', force_quotes: true, encoding: 'UTF-8' }

      csv_str = ::CSV.generate(options) do |csv|
        csv << weaknesses_brief_csv_headers

        weaknesses_brief_csv_data_rows.each { |row| csv << row }
      end

      "\uFEFF#{csv_str}"
    end

    def weaknesses_brief_csv_headers
      [
        Review.model_name.human,
        PlanItem.human_attribute_name('project'),
        t("#{@controller}_committee_report.weaknesses_brief.weakness_title"),
        t("#{@controller}_committee_report.weaknesses_brief.description"),
        Weakness.human_attribute_name('risk'),
        t("#{@controller}_committee_report.weaknesses_brief.audit_comments"),
        FindingUserAssignment.human_attribute_name('process_owner'),
        t("#{@controller}_committee_report.weaknesses_brief.issue_date"),
        t("#{@controller}_committee_report.weaknesses_brief.first_follow_up_date"),
        t("#{@controller}_committee_report.weaknesses_brief.follow_up_date"),
        t("#{@controller}_committee_report.weaknesses_brief.distance_to_cut_date")
      ]
    end

    def weaknesses_brief_csv_data_rows
      @weaknesses.map do |weakness|
        [
          [
            weakness.implemented_audited? ? '(*) ': '',
            weakness.review.identification
          ].join,
          weakness.review.plan_item.project,
          weakness.title,
          weakness.description,
          weakness.risk_text,
          weakness.audit_comments,
          weaknesses_brief_audit_users(weakness).join("\n"),
          (
            weakness.review.conclusion_final_review ?
            l(weakness.review.conclusion_final_review.issue_date) : '-'
          ),
          (weakness.first_follow_up_date ? l(weakness.first_follow_up_date) : '-'),
          (weakness.follow_up_date ? l(weakness.follow_up_date) : '-'),
          distance_in_days_to_cut_date(weakness)
        ]
      end
    end

    def weaknesses_brief_audit_users weakness
      weakness.
        finding_user_assignments.
        select { |fua| fua.process_owner && fua.user.can_act_as_audited? }.
        map(&:user).
        map(&:full_name_with_function)
    end

    def distance_in_days_to_cut_date weakness
      if weakness.first_follow_up_date
        distance = (@cut_date - weakness.first_follow_up_date).days / 1.day

        distance.abs.to_i > 365 ? distance.abs.to_i : nil
      end
    end

    def extract_cut_date parameters
      cut_date = Timeliness.parse parameters[:cut_date], :date if parameters

      cut_date&.to_date || Time.zone.today
    end

    def add_weaknesses_brief pdf
      pdf.move_down PDF_FONT_SIZE

      if @weaknesses.present?
        add_weaknesses_brief_table                     pdf
        add_weaknesses_brief_implemented_audited_count pdf
      else
        pdf.text t("#{@controller}_committee_report.weaknesses_brief.without_weaknesses"),
          style: :italic
      end
    end

    def add_weaknesses_brief_table pdf
      pdf.font_size (PDF_FONT_SIZE * 0.5).round do
        table_options = pdf.default_table_options weaknesses_brief_column_widths(pdf)

        pdf.table(weaknesses_brief_data(pdf), table_options) do
          row(0).style(
            background_color: 'cccccc',
            padding: [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
          )
        end
      end
    end

    def add_weaknesses_brief_implemented_audited_count pdf
      pdf.move_down PDF_FONT_SIZE

      pdf.text "(*) " + t(
        'follow_up_committee_report.weaknesses_brief.implemented_audited_count',
        count: @implemented_audited_weaknesses.count,
        from_date: l(@to_date),
        to_date: l(Time.zone.today)
      ), style: :italic
    end

    def weaknesses_brief_columns
      {
        Review.model_name.human => 7,
        PlanItem.human_attribute_name('project') => 9,
        t("#{@controller}_committee_report.weaknesses_brief.weakness_title") => 10,
        t("#{@controller}_committee_report.weaknesses_brief.description") => 21,
        Weakness.human_attribute_name('risk') => 4,
        t("#{@controller}_committee_report.weaknesses_brief.audit_comments") => 20,
        FindingUserAssignment.human_attribute_name('process_owner') => 10,
        t("#{@controller}_committee_report.weaknesses_brief.issue_date") => 5,
        t("#{@controller}_committee_report.weaknesses_brief.first_follow_up_date") => 5,
        t("#{@controller}_committee_report.weaknesses_brief.follow_up_date") => 5,
        t("#{@controller}_committee_report.weaknesses_brief.distance_to_cut_date") => 4
      }
    end

    def weaknesses_brief_column_widths pdf
      weaknesses_brief_columns.map { |name, width| pdf.percent_width width }
    end

    def weaknesses_brief_column_headers pdf
      weaknesses_brief_columns.map { |name, width| "<b>#{name}</b>" }
    end

    def weaknesses_brief_data pdf
      data = @weaknesses.map do |weakness|
        [
          [
            weakness.implemented_audited? ? '(*) ' : '',
            weakness.review.identification
          ].join,
          weakness.review.plan_item.project,
          weakness.title,
          truncate(weakness.description, length: 1000),
          weakness.risk_text,
          truncate(weakness.audit_comments, length: 1000),
          weaknesses_brief_audit_users(weakness).join("\n"),
          (
            weakness.review.conclusion_final_review ?
            l(weakness.review.conclusion_final_review.issue_date) : '-'
          ),
          (weakness.first_follow_up_date ? l(weakness.first_follow_up_date) : '-'),
          (weakness.follow_up_date ? l(weakness.follow_up_date) : '-'),
          distance_in_days_to_cut_date(weakness)
        ]
      end

      data.insert 0, weaknesses_brief_column_headers(pdf)
    end

    def weaknesses_brief_order
      order_by = params[:weaknesses_brief] && params[:weaknesses_brief][:order_by]

      if order_by == 'risk'
        [
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
          "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
        ].map { |o| Arel.sql o }
      elsif order_by == 'first_follow_up_date'
        [
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'first_follow_up_date'} DESC",
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
          "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
        ].map { |o| Arel.sql o }
      else
        [
          "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} ASC",
          "#{Review.quoted_table_name}.#{Review.qcn 'identification'} ASC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'risk'} DESC",
          "#{Weakness.quoted_table_name}.#{Weakness.qcn 'review_code'} ASC"
        ].map { |o| Arel.sql o }
      end
    end
end
