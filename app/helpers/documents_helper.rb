module DocumentsHelper
  def link_to_download_document document, options = {}
    url   = url_from_document_file_model(document) || url_from_document_description(document)
    title = document.file_model&.identifier&.titleize || url
    icon  = document.file_model ? 'download-alt' : 'link'

    if url.present?
      default_options = {
        class: 'btn btn-default',
        title: title,
        data:  { ignore_unsaved_data: true }
      }

      link_to url, default_options.merge(options) do
        content_tag :span, nil, class: "icon glyphicon glyphicon-#{icon}"
      end
    end
  end

  def show_document_info document
    created_at_label = Document.human_attribute_name 'created_at'
    updated_at_label = Document.human_attribute_name 'updated_at'
    created_at_value = l document.created_at, format: :short
    updated_at_value = l document.updated_at, format: :short

    show_info [
      "#{created_at_label}: #{created_at_value}",
      "#{updated_at_label}: #{updated_at_value}"
    ].join("\n")
  end

  private

    def url_from_document_file_model document
      file_model = document.file_model

      if file_model && file_model.file? && file_model.file.cached?.blank?
        download_document_path document
      end
    end

    def url_from_document_description document
      url_regex = /(ftp|file|http|https):\/\/[\\\w\-.:%]+(\/\S*)?/

      document.description.to_s.match(url_regex) && $~[0]
    end
end
