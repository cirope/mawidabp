class Polls::ReviewPdf < Prawn::Document
  include Polls::PdfHeaders

  attr_accessor :relative_path

  def initialize report, current_organization
    @report = report
    @current_organization = current_organization
    @pdf = Prawn::Document.create_generic_pdf :portrait

    generate
  end

  def relative_path
    Prawn::Document.relative_path pdf_name, Review.table_name
  end

  private

    def generate
      pdf_add_header

      if @report.polls.present?
        pdf_add_description
        pdf_add_body
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
          if show_poll? poll
            pdf_add_review poll
            pdf_add_user poll
            pdf_add_status poll

            pdf.move_down PDF_FONT_SIZE unless i == count - 1
          end
        end
      end
    end

    def pdf_add_status poll
      pdf.text "#{Poll.human_attribute_name(:send_date)}: #{I18n.l poll.created_at.to_date, format: :long}", style: :bold
    end

    def pdf_add_review poll
      pdf.text "#{Review.model_name.human}: #{poll.pollable.review_id}", style: :bold
    end

    def pdf_add_user poll
      pdf.text "#{Poll.human_attribute_name :user}: #{poll.user.informal_name}", style: :bold
    end

    def set_answer answer
      if answer.question&.options&.any?
        "#{I18n.t("answer_options.#{answer.answer_option.option}")}"
      elsif answer.question.answer_written?
        answer.answer
      end
    end

    def save
      pdf.custom_save_as pdf_name, Review.table_name
    end

    def show_poll? poll
      poll.answers.any? { |a| show_answer? a }
    end

    def show_answer? answer
      show_answer = show_question?(answer.question) && !@report.filter_answers

      show_answer ||
        @report.filter_answers &&
        @report.answer_option == answer.answer_option&.option
    end

    def show_question? question
      if @report.question.present?
        question.question =~ /#{Regexp.escape @report.question}/i
      else
        true
      end
    end
end
