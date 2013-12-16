class FollowUpCommitteeController < ApplicationController
  include Reports::ControlObjectiveStats
  include Reports::ProcessControlStats
  include Reports::WeaknessesByRiskReport
  include Reports::FixedWeaknessesReport
  include Reports::SynthesisReport
  include Reports::QAIndicators
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
