module FileModelHelper
  def file_model model
    model.build_file_model unless model.file_model
  end

  def link_to_download model
    file_model = model.file_model

    if file_model && file_model.file? && file_model.file.cached?.blank?
      options = {
        class: 'btn btn-default',
        title: file_model.identifier.titleize,
        data:  { ignore_unsaved_data: true }
      }

      link_to file_model.file.url, options do
        content_tag(:span, nil, class: 'icon glyphicon glyphicon-download-alt')
      end
    end
  end

  def link_to_upload model, attr = :file
    cache_column = "#{attr}_cache"
    options      = {
      class: 'glyphicon-folder-open',
      title: t('navigation.upload')
    }

    if model.send(cache_column)
      options = {
        class: 'glyphicon-file',
        title: model.identifier.to_s.titleize
      }
    end

    content_tag :span, class: 'btn btn-default file', title: options[:title] do
      content_tag(:span, nil, class: "icon glyphicon #{options[:class]}")
    end
  end

  def link_to_file description
    file_url = description.match(/(ftp|file|http|https):\/\/[\\\w\-.%]+(\/\S*)?/) && $~[0]
    url      = file_url ? file_url.strip : '#'
    classes  = 'btn btn-default'

    classes << ' hidden' unless file_url

    link_to url, class: classes, target: '_blank', data: { file_url: true } do
      content_tag :span, nil, class: 'icon glyphicon glyphicon-download-alt'
    end
  end

  def file_model_error model
    model.errors[:file_model].first ||
      Array(model.file_model&.errors[:file_file_name]).first
  end
end
