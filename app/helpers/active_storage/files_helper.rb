module ActiveStorage::FilesHelper
  def link_to_upload_file
    icon  = 'folder-open'
    title = t('navigation.upload')

    content_tag :span, class: 'btn btn-outline-secondary file', title: title do
      icon 'fas', icon
    end
  end

  def link_to_download_file file, options = {}
    default_options = {
      class: 'btn btn-outline-secondary mb-3',
      title: file.filename.to_s,
      id: "file_attachement_#{file.attachment.object_id}"
    }.merge(options)

    link_to url_for(file), default_options do
      icon 'fas', 'download'
    end
  end

  def link_to_purge_file form
    file_attachment = form.object
    out             = ''

    out << form.hidden_field(
      :_destroy,
      class: 'destroy',
      value: 0,
      id: "remove_file_attachment_hidden_#{file_attachment.object_id}"
    )

    out << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete_file'),
      data: {
        'dynamic-target' => "#file_attachement_#{file_attachment.object_id}",
        'dynamic-form-event' => 'hideItembutton'
      }
    )

    raw out
  end

  def show_link_to_download_file object, options = {}
    object.file.attached? ? link_to_download_file(object.file, options) : ''
  end

  def link_to_upload_files
    icon  = 'folder-open'
    title = t('navigation.upload')

    content_tag :span, class: 'btn btn-outline-secondary file', title: title do
      icon 'fas', icon
    end
  end

  def link_to_download_file_attachment file_attachment, options = {}
    default_options = {
      class: 'btn btn-outline-secondary mb-3',
      title: file_attachment.filename.to_s,
      id: "file_attachment_#{file_attachment.object_id}"
    }.merge(options)

    link_to url_for(file_attachment), default_options do
      icon 'fas', 'download'
    end
  end

  def link_to_purge_file_attachment form
    file_attachment = form.object
    out             = ''

    out << form.hidden_field(
      :_destroy,
      class: 'destroy',
      value: 0,
      id: "remove_file_attachment_hidden_#{file_attachment.object_id}"
    )

    out << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: {
        'dynamic-target' => "#file_attachment_#{file_attachment.object_id}",
        'dynamic-form-event' => 'hideItem'
      }
    )

    raw out
  end
end
