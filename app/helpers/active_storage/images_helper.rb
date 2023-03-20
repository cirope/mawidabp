module ActiveStorage::ImagesHelper
  def show_link_to_download_image? form
    form.object.errors[:image].empty? && form.object.image.attached?
  end

  def link_to_upload_image
    icon  = 'folder-open'
    title = t('navigation.upload')

    content_tag :span, class: 'btn btn-outline-secondary file', title: title do
      icon 'fas', icon
    end
  end

  def link_to_download_image image, options = {}
    default_options = {
      class: 'btn btn-outline-secondary mb-3',
      title: image.filename.to_s,
      id: "image_attachement_#{image.attachment.object_id}"
    }.merge(options)

    link_to url_for(image), default_options do
      icon 'fas', 'download'
    end
  end

  def link_to_purge_image form
    image_attachment = form.object
    out              = ''

    out << form.hidden_field(
      :_destroy,
      class: 'destroy',
      value: 0,
      id: "remove_image_attachment_hidden_#{image_attachment.object_id}"
    )

    out << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete_file'),
      data: {
        'dynamic-target' => "#image_attachement_#{image_attachment.object_id}",
        'dynamic-form-event' => 'hideItembutton'
      }
    )

    raw out
  end

  def show_link_to_download_image object, options = {}
    object.image.attached? ? link_to_download_image(object.image, options) : ''
  end

  def link_to_upload_images
    icon  = 'folder-open'
    title = t('navigation.upload')

    content_tag :span, class: 'btn btn-outline-secondary file', title: title do
      icon 'fas', icon
    end
  end

  def link_to_download_image_attachment image_attachment, options = {}
    default_options = {
      class: 'btn btn-outline-secondary mb-3',
      title: image_attachment.filename.to_s,
      id: "image_attachment_#{image_attachment.object_id}"
    }.merge(options)

    link_to url_for(image_attachment), default_options do
      icon 'fas', 'download'
    end
  end

  def link_to_purge_image_attachment form
    image_attachment = form.object
    out              = ''

    out << form.hidden_field(
      :_destroy,
      class: 'destroy',
      value: 0,
      id: "remove_image_attachment_hidden_#{image_attachment.object_id}"
    )

    out << link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: {
        'dynamic-target' => "#image_attachment_#{image_attachment.object_id}",
        'dynamic-form-event' => 'hideItem'
      }
    )

    raw out
  end

  def medium_image image
    # aca se va a crear un attachment nuevo con un blob nuevo el cual es un ActiveStorage::VariantRecord
    # este va a almacenar la variante que nosotros pidamos y a demanda

    # image.representation(resize_to_fit: [600, 600], format: :png) # lazy
    image.variant(resize_to_fit: [600, 600], format: :png) # direct
  end
end
