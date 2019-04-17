module FiltersHelper
  def date_filter_operators
    options = %w(= < > <= >=).map { |o| [o, o] }

    options << [t('.between'), 'between']
  end

  def filter_answer_options
    [
      [
        AnswerMultiChoice.model_name.human,
        Question::ANSWER_OPTIONS.map { |o| [t("answer_options.#{o}"), o.to_s] }
      ],
      [
        AnswerYesNo.model_name.human,
        Question::ANSWER_YES_NO_OPTIONS.map { |o| [t("answer_options.#{o}"), o.to_s] }
      ]
    ]
  end

  def filter_business_unit_options
    bus = BusinessUnit.list.order(:name).each_with_object({}) do |bu, bus|
      bus[bu.name] ||= []

      bus[bu.name] << bu.id
    end

    bus.map { |name, ids| [name, ids.to_json] }
  end
end
