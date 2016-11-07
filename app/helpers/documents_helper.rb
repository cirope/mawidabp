module DocumentsHelper
  def link_to_download_document document
    file_model = document.file_model

    if file_model && file_model.file? && file_model.file.cached?.blank?
      options = {
        class: 'btn btn-default',
        title: file_model.identifier.titleize,
        data:  { ignore_unsaved_data: true }
      }

      link_to download_document_path(document), options do
        content_tag(:span, nil, class: 'icon glyphicon glyphicon-download-alt')
      end
    end
  end
end
