# TODO: move to app/validators on Rails 5 migration
class PdfEncodingValidator < ActiveModel::EachValidator
  def validate_each record, attribute, value
    encoded_value = value&.encode('windows-1252') rescue :invalid

    if encoded_value == :invalid
      if options[:message]
        record.errors[attribute] << options[:message]
      else
        record.errors.add attribute, :pdf_encoding
      end
    end
  end
end
