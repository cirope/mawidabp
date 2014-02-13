module Reports::RescheduledBeingImplementedWeaknesses
  include Reports::Pdf

  def rescheduled_being_implemented_weaknesses_report
    init_rescheduled_vars

    if @parameters
      Weakness.being_implemented.for_current_organization.limit(100).each do |w|
        check_for_rescheduling(w)

        if @follow_up_date_modifications.present?
          # Filtro por cantidad de reprogramaciones
          if @rescheduling == 0 || @rescheduling == @follow_up_date_modifications.count ||
            @rescheduling == @rescheduling_options.last.last &&
            @rescheduling <= @follow_up_date_modifications.count

            add_weakness_data(w)
          end
        end
      end
    end
  end

  def init_rescheduled_vars
    @title = t 'follow_up_committee.rescheduled_being_implemented_weaknesses_report_title'
    @parameters = params[:rescheduled_being_implemented_weaknesses_report]
    @from_date, @to_date = *make_date_range(@parameters)
    @rescheduling_options = [[1,1], [2,2], [3,3], ['+', 4]]
    @rescheduling = @parameters[:rescheduling].try(:to_i) if @parameters
    @detailed = @parameters[:detailed].to_i if @parameters

    @weaknesses_data = []
    if @rescheduling && @rescheduling > 0
      @filters = ["<strong>#{t 'follow_up_committee_report.rescheduling'}</strong>#{@rescheduling ==
        @rescheduling_options.last.last ?
        " #{t('label.greater_or_equal_than')}" : ' ='} #{@rescheduling}"]
    end
  end

  def check_for_rescheduling(w)
    @follow_up_date_modifications = []
    @rescheduled_being_implemented_weaknesses = []

    @last_version = w.versions.size - 1

    if @last_version >= 0
      (0..@last_version).each do |i|
        calculate_weakness_data(i, w)
        add_rescheduled_data(i,w)
      end
    end
  end

  def calculate_weakness_data(version_index, weakness)
    if version_index == @last_version
      version = weakness.versions[version_index].reify
      next_version = weakness
    else
      version = weakness.versions[version_index].reify rescue nil
      next_version = weakness.versions[version_index + 1].reify rescue nil
    end

    @follow_up_date = version.try(:follow_up_date)
    @next_follow_up_date = next_version.try(:follow_up_date)
    @being_implemented = next_version.try(:being_implemented?)
  end

  def get_audited(w)
    audited = w.users.select(&:audited?).map do |u|
      w.process_owners.include?(u) ?
      "<strong>#{u.full_name} (#{FindingUserAssignment.human_attribute_name(:process_owner)})</strong>" :
      u.full_name
    end
  end

  def add_weakness_data(w)
    audited = get_audited w

    @rescheduled_being_implemented_weaknesses =
      "<strong>#{Review.model_name.human}</strong>: #{w.review.to_s}",
      "<strong>#{Weakness.human_attribute_name(:review_code)}</strong>: #{w.review_code}",
      "<strong>#{Weakness.human_attribute_name(:state)}</strong>: #{w.state_text}",
      "<strong>#{Weakness.human_attribute_name(:risk)}</strong>: #{w.risk_text}",
      "<strong>#{Weakness.human_attribute_name(:priority)}</strong>: #{w.priority_text}",
      "<strong>#{Weakness.human_attribute_name(:follow_up_date)}</strong>: #{l(w.follow_up_date, :format => :long)}",
      ("<strong>#{Weakness.human_attribute_name(:origination_date)}</strong>: #{l(w.origination_date, :format => :long)}" if w.origination_date),
      "<strong>#{I18n.t('finding.audited', :count => audited.size)}</strong>: #{audited.join('; ')}",
      "<strong>#{Weakness.human_attribute_name(:description)}</strong>: #{w.description}",
      "<strong>#{I18n.t('follow_up_committee_report.rescheduling')}</strong>:\n #{@follow_up_date_modifications.join("\n")}"

    add_detailed_data(w) if @detailed == 1

    @weaknesses_data << @rescheduled_being_implemented_weaknesses
  end

  def add_detailed_data(w)
    @rescheduled_being_implemented_weaknesses <<
      "<strong>#{Weakness.human_attribute_name(:audit_comments)}</strong>: #{w.audit_comments}"
    @rescheduled_being_implemented_weaknesses <<
      "<strong>#{Weakness.human_attribute_name(:answer)}</strong>: #{w.answer}"
  end

  def add_rescheduled_data(i,w)
    if @follow_up_date && @next_follow_up_date && @being_implemented
      # Si se reprogramó hacia el futuro
      if @follow_up_date != @next_follow_up_date && @follow_up_date < @next_follow_up_date
       # Si se repgrogramó entre las fechas ingresadas
        if w.versions[i].created_at.to_date >= @from_date &&
         w.versions[i].created_at.to_date <= @to_date
          modification_date = l w.versions[i].created_at.to_date, :format => :long
          modificator = User.find(w.versions[i].whodunnit).informal_name if w.versions[i].whodunnit
          old_date = l @follow_up_date, :format => :long
          new_date = l @next_follow_up_date, :format => :long
          @follow_up_date_modifications << " • #{modification_date} (#{modificator}: #{old_date} #{t 'label.by'} #{new_date})"
        end
      end
    end
  end

  def create_rescheduled_being_implemented_weaknesses_report
    self.rescheduled_being_implemented_weaknesses_report

    pdf = init_pdf(params[:report_title], params[:report_subtitle])
    add_pdf_description(pdf, 'follow_up', @from_date, @to_date)
    pdf.move_down PDF_FONT_SIZE

    add_weaknesses_data(pdf)
    add_pdf_filters(pdf, 'follow_up', @filters) if @filters.try(:present?)
    save_pdf(pdf, 'follow_up', @from_date, @to_date, 'rescheduled_being_implemented_weaknesses_report')
    redirect_to_pdf('follow_up', @from_date, @to_date, 'rescheduled_being_implemented_weaknesses_report')
  end

  def add_weaknesses_data(pdf)
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
  end
end
