module PollsHelper
  def answer_options_collection form
    form.input :answer_option_id,
      as: :radio_buttons,
      label: '&nbsp;'.html_safe,
      value_method: :first,
      label_method: :second,
      collection: answer_options(form.object.question),
      wrapper_html: { class: 'mt-n3' },
      item_wrapper_class: 'custom-control custom-radio'
  end

  private

    def answer_options question
      question.answer_options.map { |o| [o.id, t("answer_options.#{o.option}")] }
    end
end
