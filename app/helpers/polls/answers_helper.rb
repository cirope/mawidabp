module Polls::AnswersHelper
  def show_poll? poll
    poll.answers.any? { |a| show_answer? a }
  end

  def show_answer? answer
    show_answer = show_question?(answer.question) && !@report.filter_answers

    show_answer ||
      @report.filter_answers &&
      @report.answer_option == answer.answer_option&.option
  end

  def link_to_download_attached_file answer_form
    answer = answer_form.object

    if answer.attached? && answer.attached.cached?.blank?
      options = {
        class: 'btn btn-outline-secondary mb-3',
        title: answer.attached.identifier.titleize,
        data: { ignore_unsaved_data: true },
        id: "answer_attached_#{answer.object_id}"
      }

      link_to answer.attached.url, options do
        icon 'fas', 'download'
      end
    end
  end

  def link_to_remove_attached_file form
    answer = form.object
    out    = ''

    if form.object.attached?
      out << form.hidden_field(
        :remove_attached,
        class: 'destroy',
        value: 0,
        id: "remove_attached_hidden_#{answer.object_id}"
      )
      out << link_to(
        icon('fas', 'times-circle'), '#',
        title: t('label.delete'),
        data: {
          'dynamic-target' => "#answer_attached_#{answer.object_id}",
          'dynamic-form-event' => 'hideItembutton',
          'show-tooltip' => true
        }
      )
    end

    raw out
  end

  private

    def show_question? question
      if @report.question.present?
        question.question =~ /#{Regexp.escape @report.question}/i
      else
        true
      end
    end
end
