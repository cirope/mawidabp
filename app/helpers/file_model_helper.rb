module FileModelHelper
  def file_model model
    model.build_file_model unless model.file_model
  end

  def link_to_download model
    file_model = model.file_model

    if file_model && file_model.file? && file_model.file.cached?.blank?
      options = {
        class: 'btn btn-outline-secondary',
        title: file_model.identifier.titleize,
        data:  { ignore_unsaved_data: true }
      }

      link_to file_model.file.url, options do
        icon 'fas', 'download'
      end
    end
  end

  def link_to_upload model, attr = :file
    cache_column = "#{attr}_cache"
    icon         = 'folder-open'
    title        = t('navigation.upload')

    if model.send(cache_column)
      icon  = 'file'
      title = model.identifier.to_s.titleize
    end

    content_tag :span, class: 'btn btn-outline-secondary file', title: title do
      icon 'fas', icon
    end
  end

  def link_to_file description
    file_url = description.match(/(ftp|file|http|https):\/\/[\\\w\-.:%]+(\/\S*)?/) && $~[0]
    url      = file_url ? file_url.strip : '#'
    options  = {
      class: 'btn btn-outline-secondary',
      target: '_blank',
      hidden: file_url.blank?,
      data: { file_url: true }
    }

    link_to url, options do
      icon 'fas', 'download'
    end
  end

  def file_model_error model
    model.errors[:file_model].first ||
      Array(model.file_model&.errors[:file_file_name]).first
  end
end
