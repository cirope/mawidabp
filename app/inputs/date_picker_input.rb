class DatePickerInput < SimpleForm::Inputs::Base
  def input
    @builder.text_field attribute_name, input_options
  end

  def input_html_classes
    super.push('form-control')
  end

  private

    def value
      I18n.l object.send(attribute_name) if object.send(attribute_name)
    end

    def input_options
      input_html_options.reverse_merge(
        value: value,
        autocomplete: 'off'
      ).merge(data: data_options)
    end

    def data_options
      original_data_options = input_html_options[:data] || {}

      original_data_options.reverse_merge(date_picker: true)
    end
end
