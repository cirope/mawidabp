module PollsHelper
  def answer_options_collection form
    form.collection_radio_buttons(
      :answer_option_id, answer_options(form.object.question), :first, :last,
      item_wrapper_tag: :div,
      item_wrapper_class: :radio
    )
  end

  def answer_options question
    question.answer_options.map do |o|
      [o.id, t("activerecord.attributes.answer_option.options.#{o.option}")]
    end
  end
end
