class FollowUpCommitteeController < ApplicationController
  include Reports::ControlObjectiveStats
  include Reports::ProcessControlStats
  include Reports::WeaknessesByRiskReport
  include Reports::FixedWeaknessesReport
  include Reports::SynthesisReport
  include Parameters::Risk

  before_action :auth, :load_privileges, :check_privileges

  # Muestra una lista con los reportes disponibles
  #
  # * GET /follow_up_committee
  def index
    @title = t 'follow_up_committee.index_title'

    respond_to do |format|
      format.html
    end
  end

  # Crea un PDF con un resumen de indicadores de calidad para un determinado
  # rango de fechas
  #
  # * GET /follow_up_committees/qa_indicators
  def qa_indicators
    @title = t('follow_up_committee.qa_indicators_title')
    @from_date, @to_date = *make_date_range(params[:qa_indicators])
    @periods = periods_for_interval
    @columns = [
      ['indicator', t('follow_up_committee.qa_indicators.indicator')],
      ['value', t('follow_up_committee.qa_indicators.value')]
    ]
    conclusion_reviews = ConclusionFinalReview.list_all_by_date(
      @from_date, @to_date
    )
    params = { :start => @from_date, :end => @to_date }
    @indicators = {}

    # Ancient weaknesses rate
    medium_risk_days = medium_risk_total = 0
    highest_risk_days = highest_risk_total = 0

    # Tomo todos los informes de definitivos sin tener en cuenta el filtro de fechas
    ConclusionFinalReview.list.each do |cfr|
      medium_risk_weaknesses = cfr.review.weaknesses.with_medium_risk.being_implemented
      highest_risk_weaknesses = cfr.review.weaknesses.with_highest_risk.being_implemented

      medium_risk_weaknesses.each do |w|
        medium_risk_days += (Date.today - w.origination_date).abs.round
        medium_risk_total += 1
      end

      highest_risk_weaknesses.each do |w|
        highest_risk_days += (Date.today - w.origination_date).abs.round
        highest_risk_total += 1
      end
    end

    ancient_medium_risk_weaknesses = medium_risk_total > 0 ?
                                                  (medium_risk_days / medium_risk_total).round : nil

    ancient_highest_risk_weaknesses = highest_risk_total > 0 ?
                                                  (highest_risk_days / highest_risk_total).round : nil


    @ancient_medium_risk_label = "#{t('follow_up_committee.qa_indicators.indicators.ancient_medium_risk_weaknesses')}: #{t('label.day', :count => ancient_medium_risk_weaknesses)}" if ancient_medium_risk_weaknesses

    @ancient_highest_risk_label = "#{t('follow_up_committee.qa_indicators.indicators.ancient_highest_risk_weaknesses')}: #{t('label.day', :count => ancient_highest_risk_weaknesses)}" if ancient_highest_risk_weaknesses

    @periods.each do |period|
      indicators = {}
      cfrs = conclusion_reviews.for_period(period).list_all_by_date(@from_date, @to_date)
      row_order = [
        ['%.1f%', :highest_solution_rate],
        ['%.1f%', :oportunities_solution_rate],
        ['%.1f%', :digitalized],
        ['%d%', :score_average],
        ['%.1f%', :production_level]
      ]

      # Highest risk weaknesses solution rate
      pending_highest_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.weaknesses.with_highest_risk.where(
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values
        ).count
      end

      resolved_highest_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.weaknesses.with_highest_risk.where(
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values - Weakness::PENDING_STATUS
        ).count
      end

      indicators[:highest_solution_rate] = pending_highest_risk > 0 ?
        (resolved_highest_risk / pending_highest_risk.to_f) * 100 : nil

      # Oportunities solution rate
      pending_oportunities = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.oportunities.where(
          :state => Oportunity::STATUS.except(Oportunity::EXCLUDE_FROM_REPORTS_STATUS).values
        ).count
      end

      resolved_oportunities = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.oportunities.where(
          :state => Oportunity::STATUS.except(Oportunity::EXCLUDE_FROM_REPORTS_STATUS).values - Oportunity::PENDING_STATUS
        ).count
      end

      indicators[:oportunities_solution_rate] = pending_oportunities > 0 ?
        (resolved_oportunities / pending_oportunities.to_f) * 100 : nil

      # Medium risk weaknesses solution rate
      pending_medium_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.weaknesses.where(
          'state IN(:state) AND (highest_risk - 1) = risk',
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values
        ).count
      end

      resolved_medium_risk = cfrs.inject(0.0) do |ct, cr|
        ct + cr.review.weaknesses.where(
          'state IN(:state) AND (highest_risk - 1) = risk',
          :state => Weakness::STATUS.except(Weakness::EXCLUDE_FROM_REPORTS_STATUS).values - Weakness::PENDING_STATUS
        ).count
      end

      indicators[:medium_solution_rate] = pending_medium_risk > 0 ?
        (resolved_medium_risk / pending_medium_risk.to_f) * 100 : nil

      # Production level
      reviews_count = period.plans.inject(0.0) do |pt, p|
        pt + p.plan_items.joins(
          :review => :conclusion_final_review
        ).with_business_unit.between(params[:start], params[:end]).count
      end
      plan_items_count = period.plans.inject(0.0) do |pt, p|
        pt + p.plan_items.with_business_unit.between(
          params[:start], params[:end]
        ).count
      end

      indicators[:production_level] = plan_items_count > 0 ?
        (reviews_count / plan_items_count.to_f) * 100 : nil

      # Reviews score average
      internal_cfrs = cfrs.internal_audit.includes(:review)
      scores = []

      BusinessUnitType.list.each do |but|
        score = 0
        total = 0
        internal_cfrs.each do |cfrs|
          if cfrs.review.business_unit.business_unit_type_id == but.id
            score += cfrs.review.score.to_f
            total += 1
          end
        end

        scores << (score / total) unless total == 0
      end

      scores.size == 0 ? indicators[:score_average] = 0 :
        indicators[:score_average] = (scores.inject(0) { |i, score | i + score  } / scores.size).round

      # Work papers digitalization
      wps = WorkPaper.includes(:owner, :file_model).where(
        'created_at BETWEEN :start AND :end', params
      ).select { |wp| wp.owner.try(:is_in_a_final_review?) }

      wps_with_files = wps.select { |wp| wp.file_model.try(:file?) }

      indicators[:digitalized] = wps.size > 0 ?
        (wps_with_files.size.to_f / wps.size) * 100 : nil

      @indicators[period] ||= []
      @indicators[period] << {
        :column_data => row_order.map do |mask, i|
          {
            'indicator' => t("follow_up_committee_report.qa_indicators.indicators.#{i}"),
            'value' => (mask % indicators[i] if indicators[i])
          }
        end
      }
    end
  end

  # Crea un PDF con un resumen de indicadores de calidad para un determinado
  # rango de fechas
  #
  # * POST /follow_up_committees/create_qa_indicators
  def create_qa_indicators
    self.qa_indicators

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    @periods.each do |period|
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title "#{Period.model_name.human}: #{period.inspect}",
        (PDF_FONT_SIZE * 1.25).round, :left
      pdf.move_down PDF_FONT_SIZE

      @indicators[period].each do |data|
        columns = {}
        column_data, column_headers, column_widths = [], [], []

        @columns.each do |col_name|
          column_headers << "<b>#{col_name.last}</b>"
          column_widths << pdf.percent_width(50)
        end

        data[:column_data].each do |row|
          new_row = []

          row.each do |column_name, column_content|
            new_row << (column_content.present? ? column_content :
              (t'follow_up_committee.qa_indicators.without_data'))
          end

          column_data << new_row
        end

        unless column_data.blank?
          pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
            table_options = pdf.default_table_options(column_widths)

            pdf.table(column_data.insert(0, column_headers), table_options) do
            row(0).style(
              :background_color => 'cccccc',
              :padding => [(PDF_FONT_SIZE * 0.5).round, (PDF_FONT_SIZE * 0.3).round]
            )
            end
          end
        else
          pdf.text(
            t('follow_up_committee.qa_indicators.without_audits_in_the_period'),
            :style => :italic)
        end
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text @ancient_medium_risk_label if @ancient_medium_risk_label
      pdf.text @ancient_highest_risk_label if @ancient_highest_risk_label
    end

    pdf.custom_save_as(
      t('follow_up_committee.qa_indicators.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'qa_indicators', 0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.qa_indicators.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'qa_indicators', 0)
  end

  def rescheduled_being_implemented_weaknesses_report
    @title = t 'follow_up_committee.rescheduled_being_implemented_weaknesses_report_title'
    parameters = params[:rescheduled_being_implemented_weaknesses_report]
    @from_date, @to_date = *make_date_range(parameters)
    @rescheduling_options = [[1,1], [2,2], [3,3], ['+', 4]]
    @rescheduling = parameters[:rescheduling].try(:to_i) if parameters
    detailed = parameters[:detailed].to_i if parameters

    @weaknesses_data = []
    if @rescheduling && @rescheduling > 0
      @filters = ["<b>#{t 'follow_up_committee_report.rescheduling'}</b>#{@rescheduling ==
        @rescheduling_options.last.last ?
        " #{t('label.greater_or_equal_than')}" : ' ='} #{@rescheduling}"]
    end

    if parameters
      Weakness.being_implemented.for_current_organization.each do |w|
        follow_up_date_modifications = []
        rescheduled_being_implemented_weaknesses = []
        last_version = w.versions.size - 1

        if last_version >= 0
          (0..last_version).each do |i|
            if i == last_version
              version = w.versions[i].reify
              next_version = w
            else
              version = w.versions[i].reify rescue nil
              next_version = w.versions[i + 1].reify rescue nil
            end

            follow_up_date = version.try(:follow_up_date)
            next_follow_up_date = next_version.try(:follow_up_date)
            being_implemented = next_version.try(:being_implemented?)

            if follow_up_date && next_follow_up_date && being_implemented
              # Si se reprogramó hacia el futuro
              if follow_up_date != next_follow_up_date && follow_up_date < next_follow_up_date
               # Si se repgrogramó entre las fechas ingresadas
                if w.versions[i].created_at.to_date >= @from_date &&
                 w.versions[i].created_at.to_date <= @to_date
                  modification_date = l w.versions[i].created_at.to_date, :format => :long
                  modificator = User.find(w.versions[i].whodunnit).informal_name if w.versions[i].whodunnit
                  old_date = l follow_up_date, :format => :long
                  new_date = l next_follow_up_date, :format => :long
                  follow_up_date_modifications << " • #{modification_date} (#{modificator}: #{old_date} #{t 'label.by'} #{new_date})"
                end
              end
            end
          end
        end

        if follow_up_date_modifications.present?
          # Filtro por cantidad de reprogramaciones
          if @rescheduling == 0 || @rescheduling == follow_up_date_modifications.count ||
            @rescheduling == @rescheduling_options.last.last &&
            @rescheduling <= follow_up_date_modifications.count

            audited = w.users.select(&:audited?).map do |u|
              w.process_owners.include?(u) ?
              "<b>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</b>" :
              u.full_name
            end

            rescheduled_being_implemented_weaknesses =
              "<b>#{Review.model_name.human}</b>: #{w.review.to_s}",
              "<b>#{Weakness.human_attribute_name(:review_code)}</b>: #{w.review_code}",
              "<b>#{Weakness.human_attribute_name(:state)}</b>: #{w.state_text}",
              "<b>#{Weakness.human_attribute_name(:risk)}</b>: #{w.risk_text}",
              "<b>#{Weakness.human_attribute_name(:priority)}</b>: #{w.priority_text}",
              "<b>#{Weakness.human_attribute_name(:follow_up_date)}</b>: #{l(w.follow_up_date, :format => :long)}",
              ("<b>#{Weakness.human_attribute_name(:origination_date)}</b>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
              "<b>#{I18n.t('finding.audited', :count => audited.size)}</b>: #{audited.join('; ')}",
              "<b>#{Weakness.human_attribute_name(:description)}</b>: #{w.description}",
              "<b>#{I18n.t('follow_up_committee_report.rescheduling')}</b>:\n #{follow_up_date_modifications.join("\n")}"

            if detailed == 1
              rescheduled_being_implemented_weaknesses <<
                "<b>#{Weakness.human_attribute_name(:audit_comments)}</b>: #{w.audit_comments}"
              rescheduled_being_implemented_weaknesses <<
                "<b>#{Weakness.human_attribute_name(:answer)}</b>: #{w.answer}"
            end

            @weaknesses_data << rescheduled_being_implemented_weaknesses
          end
        end
      end
    end
  end

  def create_rescheduled_being_implemented_weaknesses_report
    self.rescheduled_being_implemented_weaknesses_report

    pdf = Prawn::Document.create_generic_pdf :landscape

    pdf.add_generic_report_header current_organization

    pdf.add_title params[:report_title], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_title params[:report_subtitle], PDF_FONT_SIZE, :center

    pdf.move_down PDF_FONT_SIZE

    pdf.add_description_item(
      t('follow_up_committee.period.title'),
      t('follow_up_committee.period.range',
        :from_date => l(@from_date, :format => :long),
        :to_date => l(@to_date, :format => :long)))

    pdf.move_down PDF_FONT_SIZE

    unless @weaknesses_data.blank?
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        @weaknesses_data.each do |data|
          data.each do |weakness|
            pdf.text weakness, :inline_format => true
          end
          pdf.move_down PDF_FONT_SIZE
        end
      end
    else
      pdf.text(
        t('follow_up_committee.rescheduled_being_implemented_weaknesses_report.without_data'))
    end

    if @filters.try(:present?)
      pdf.move_down PDF_FONT_SIZE
      pdf.text t('follow_up_committee.applied_filters',
        :filters => @filters.to_sentence, :count => @filters.size),
        :font_size => (PDF_FONT_SIZE * 0.75).round, :justification => :full,
        :inline_format => true
    end

    pdf.custom_save_as(
      t('follow_up_committee.rescheduled_being_implemented_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'rescheduled_being_implemented_weaknesses_report', 0)

    redirect_to Prawn::Document.relative_path(
      t('follow_up_committee.rescheduled_being_implemented_weaknesses_report.pdf_name',
        :from_date => @from_date.to_formatted_s(:db),
        :to_date => @to_date.to_formatted_s(:db)), 'rescheduled_being_implemented_weaknesses_report', 0)

  end

  private
    def load_privileges #:nodoc:
      @action_privileges.update(
        :qa_indicators => :read,
        :create_qa_indicators => :read,
        :synthesis_report => :read,
        :create_synthesis_report => :read,
        :high_risk_weaknesses_report => :read,
        :create_high_risk_weaknesses_report => :read,
        :fixed_weaknesses_report => :read,
        :create_fixed_weaknesses_report => :read,
        :control_objective_stats => :read,
        :create_control_objective_stats => :read,
        :process_control_stats => :read,
        :create_process_control_stats => :read,
        :rescheduled_being_implemented_weaknesses_report => :read,
        :create_rescheduled_being_implemented_weaknesses_report => :read
      )
    end
end
