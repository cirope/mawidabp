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
    BusinessUnitType.list.map do |business_unit_type|
      options = business_unit_type.business_units.map do |business_unit|
        [business_unit.name, business_unit.id]
      end

      [business_unit_type.name, options]
    end
  end
end
