module QuestionnairesHelper
  def pollable_type_field(form)
    collection = Questionnaire::POLLABLE_TYPES.map do |type|
      [type.constantize.model_name.human, type]
    end

    form.input :pollable_type, collection: collection,
      prompt: t('helpers.select.prompt')
  end
end
