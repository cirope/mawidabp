class Polls::AnswerPDF < Prawn::Document
  include Polls::PDFHeaders
  include Polls::PDFScores

  attr_accessor :relative_path

  def initialize report, current_organization
    @report = report
    @current_organization = current_organization
    @pdf = Prawn::Document.create_generic_pdf :portrait

    generate
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, Answer.table_name
  end

  private

    def generate
      pdf_add_header

      if @report.polls.present?
        pdf_add_description
        pdf_add_body
        pdf_add_scores
      else
        pdf.text I18n.t('polls.without_data')
      end

      save
    end

    def pdf_add_body
      pdf.move_down PDF_FONT_SIZE

      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        count = @report.polls.size

        @report.polls.each_with_index do |poll, i|
          pdf_add_user poll
          pdf_add_affected_user poll
          pdf_add_status poll
          pdf_add_answers poll
          pdf_add_comments poll

          pdf.move_down PDF_FONT_SIZE unless i == count - 1
        end
      end
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
      pdf.text "#{Poll.human_attribute_name :user}: #{poll.user.informal_name}", style: :bold
    end

    def pdf_add_affected_user poll
      if poll.about
        pdf.text "#{Poll.human_attribute_name :affected_user}: #{poll.about.informal_name}", style: :bold
      end
    end

    def pdf_add_answers poll
      pdf.move_down PDF_FONT_SIZE * 0.5
      pdf.text Questionnaire.human_attribute_name(:questions), style: :bold

      poll.answers.each do |answer|
        ans = set_answer(answer) if poll.answered?

        pdf.move_down PDF_FONT_SIZE * 0.25
        pdf.text answer.question.question

        pdf.indent PDF_FONT_SIZE do
          pdf.move_down PDF_FONT_SIZE * 0.25
          pdf.text ans

          if answer.comments.present?
            pdf.text "#{Answer.human_attribute_name :comments}: <i>#{answer.comments}</i>", inline_format: true
          end
        end
      end
    end

    def set_answer answer
      if answer.question.options.any?
        "#{I18n.t("answer_options.#{answer.answer_option.option}")}"
      elsif answer.question.answer_written?
        answer.answer
      end
    end

    def save
      pdf.custom_save_as pdf_name, Answer.table_name
    end
end
