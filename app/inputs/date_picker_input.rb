class DatePickerInput < SimpleForm::Inputs::Base
  def input wrapper_options
    @builder.text_field attribute_name, merge_wrapper_options(input_options, wrapper_options)
  end

  private

    def value
      if object.present? && object.send(attribute_name)
        I18n.l object.send(attribute_name) rescue nil
      else
        input_html_options[:value]
      end
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
