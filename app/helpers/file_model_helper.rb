module FileModelHelper
  def file_model model
    model.build_file_model unless model.file_model
  end

  def link_to_download model
    file_model = model.file_model

    if file_model && file_model.file? && file_model.file.cached?.blank?
      link_to file_model.file.url, class: 'btn btn-default',
        title: file_model.identifier.titleize do
        content_tag(:span, nil, class: 'icon glyphicon glyphicon-download-alt')
      end
    end
  end

  def link_to_upload model
    options = { class: 'glyphicon-folder-open', title: t('navigation.upload') }

    if model.file_cache
      options = { class: 'glyphicon-file', title: model.identifier.titleize }
    end

    content_tag :span, class: 'btn btn-default file', title: options[:title] do
      content_tag(:span, nil, class: "icon glyphicon #{options[:class]}")
    end
  end
end
