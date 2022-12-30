module DocumentsHelper
  def show_document_info document
    created_at_label = Document.human_attribute_name 'created_at'
    updated_at_label = Document.human_attribute_name 'updated_at'
    created_at_value = l document.created_at, format: :short
    updated_at_value = l document.updated_at, format: :short

    show_info [
      "#{created_at_label}: #{created_at_value}",
      "#{updated_at_label}: #{updated_at_value}"
    ].join(' | ')
  end

  private

    def url_from_document_description document
      url_regex = /(ftp|file|http|https):\/\/[\\\w\-.:%]+(\/\S*)?/

      document.description.to_s.match(url_regex) && $~[0]
    end
end
