module DocumentsHelper
  def link_to_download_document document, options = {}
    file_model = document.file_model

    if file_model && file_model.file? && file_model.file.cached?.blank?
      default_options = {
        class: 'btn btn-default',
        title: file_model.identifier.titleize,
        data:  { ignore_unsaved_data: true }
      }

      link_to download_document_path(document), default_options.merge(options) do
        content_tag(:span, nil, class: 'icon glyphicon glyphicon-download-alt')
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
end
