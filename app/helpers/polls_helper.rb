module PollsHelper
  def answer_options_collection form
    form.input :answer_option_id,
      as: :radio_buttons,
      label: '&nbsp;'.html_safe,
      value_method: :first,
      label_method: :second,
      collection: answer_options(form.object.question)
  end

  def link_to_download_answer_attached answer, options = {}
    if answer.attached?
      options = {
        class: 'btn btn-outline-secondary',
        title: answer.attached.identifier.titleize,
        data: { ignore_unsaved_data: true }
        }.merge(options)

      link_to answer.attached.url, options do
        icon 'fas', 'download'
      end
    end
  end

  private

    def answer_options question
      question.answer_options.map { |o| [o.id, t("answer_options.#{o.option}")] }
    end
end
