class DatePickerInput < SimpleForm::Inputs::Base
  def input
    @builder.text_field(
      attribute_name,
      input_html_options.reverse_merge(
        value: (I18n.l(object.send(attribute_name)) if object.send(attribute_name)),
        autocomplete: 'off', data: { date_picker: true }
      )
    ).html_safe
  end

  def input_html_classes
    super.push('form-control')
  end
end
