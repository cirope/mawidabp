module PollsHelper
  def answer_option_field(form)
    collection = form.object.question.answer_options.map do |o|
      [t("activerecord.attributes.answer_option.options.#{o.option}"), o.id]
    end

    form.input :answer_option_id, collection: collection, as: :radio_buttons, label: false
  end
end
