class Polls::AnswerPdf < Prawn::Document
  attr_accessor :relative_path

  def initialize report, current_organization
    @report = report
    @current_organization = current_organization
    @pdf = Prawn::Document.create_generic_pdf :portrait

    generate
  end

  def relative_path
    Prawn::Document.relative_path(
      I18n.t('poll.summary_pdf_name',
      from_date: @report.from_date.to_s(:db), to_date: @report.to_date.to_s(:db)),
      'answers', 0
    )
  end

  private

    def generate
      pdf_add_header

      if @report.polls.present?
        pdf_add_description
        pdf_add_body
      else
        pdf.text I18n.t('poll.without_data')
      end

      save
    end

    def pdf_add_body
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        @report.polls.each do |poll|
          pdf_add_user poll
          pdf_add_status poll
          pdf_add_answers poll
          pdf_add_comments poll

          pdf.move_down PDF_FONT_SIZE
        end
      end

      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{I18n.t('poll.total_answered')}: #{@report.answered}"
      pdf.text "#{I18n.t('poll.total_unanswered')}: #{@report.unanswered}"
      pdf.move_down PDF_FONT_SIZE
      pdf.text "#{I18n.t('poll.score')}: #{@report.calification}%"
    end

    def pdf_add_comments poll
      if poll.comments.present?
        pdf.text "#{Poll.human_attribute_name :comments}: #{poll.comments}"
      end
    end

    def pdf_add_status poll
      pdf.text "#{Poll.human_attribute_name :answered}: #{poll.answered ? I18n.t('label.yes') : I18n.t('label.no')}"
      pdf.text "#{Poll.human_attribute_name(:send_date)}: #{I18n.l poll.created_at.to_date, format: :long}"

      if poll.answered?
        pdf.text "#{Poll.human_attribute_name(:answer_date)}: #{I18n.l poll.updated_at.to_date, format: :long}"
      end
    end

    def pdf_add_user poll
      if poll.user
        pdf.text "#{Poll.human_attribute_name :user_id}: #{poll.user.informal_name}", style: :bold
      elsif poll.customer_email
        pdf.text "#{Poll.human_attribute_name :customer_email}: #{poll.customer_email}", style: :bold
      end
    end

    def pdf_add_answers poll
      pdf.text "#{Questionnaire.human_attribute_name :questions}:"

      poll.answers.each do |answer|
        ans = ''
        if poll.answered?
          if answer.question.answer_multi_choice?
            ans = "#{t("activerecord.attributes.answer_option.options.#{answer.answer_option.option}")}"
          elsif answer.question.answer_written?
            ans = answer.answer
          end
        end

        pdf.text "#{answer.question.question} #{ans}"

        if answer.comments.present?
          pdf.text "#{Answer.human_attribute_name :comments}: #{answer.comments}"
        end
      end
    end

    def save
      pdf.custom_save_as(
        I18n.t('poll.summary_pdf_name',
        from_date: @report.from_date.to_s(:db), to_date: @report.to_date.to_s(:db)
      ), 'answers', 0)
    end

    def pdf_add_header
      pdf.add_generic_report_header @current_organization
      pdf.add_title @report.params[:report_title], PDF_FONT_SIZE, :center
      pdf.move_down PDF_FONT_SIZE
      pdf.add_title @report.params[:report_subtitle], PDF_FONT_SIZE, :center
      pdf.move_down PDF_FONT_SIZE * 2
      pdf.add_description_item(
        I18n.t('activerecord.attributes.poll.send_date'),
        I18n.t('conclusion_committee_report.period.range',
          from_date: I18n.l(@report.from_date, format: :long),
          to_date: I18n.l(@report.to_date, format: :long)
        )
      )
      pdf.move_down PDF_FONT_SIZE
    end

    def pdf_add_description
      pdf.add_description_item(Questionnaire.model_name.human, @report.questionnaire.name)
      pdf.move_down PDF_FONT_SIZE * 2
    end

    def pdf
      @pdf
    end
end
