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
      pdf.font_size((PDF_FONT_SIZE * 0.75).round) do
        @report.polls.each do |poll|
          pdf_add_user poll
          pdf_add_status poll
          pdf_add_answers poll
          pdf_add_comments poll
          pdf.move_down PDF_FONT_SIZE
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
            ans = "#{I18n.t("activerecord.attributes.answer_option.options.#{answer.answer_option.option}")}"
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
      pdf.custom_save_as pdf_name, Answer.table_name
    end
end
