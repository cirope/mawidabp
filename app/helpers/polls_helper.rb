module PollsHelper
  def answer_options question
    question.answer_options.map do |o|
      [o.id, t("activerecord.attributes.answer_option.options.#{o.option}")]
    end
  end
end
