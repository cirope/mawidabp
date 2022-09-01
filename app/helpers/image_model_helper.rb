module ImageModelHelper
  def link_to_download_image image_form
    image_model = image_form.object

    if image_model && image_model.image? && image_model.image.cached?.blank?
      options = {
        class: 'btn btn-outline-secondary',
        title: image_model.identifier.titleize,
        data: { ignore_unsaved_data: true },
        id: "#{image_model.class.name.underscore}_#{image_model.object_id}"
      }

      link_to image_model.image.url, options do
        icon 'fas', 'download'
      end
    end
  end

  def link_to_remove_image(image_form)
    image_model = image_form.object
    out         = ''

    if image_form.object.persisted?
      out << image_form.hidden_field(
        :_destroy,
        class: 'destroy',
        value: 0,
        id: "remove_#{image_model.class.name.underscore}_hidden_#{image_model.object_id}"
      )
      out << link_to(
        icon('fas', 'times-circle'), '#',
        title: t('label.delete'),
        class: 'ml-2',
        data: {
          'dynamic-target' => "##{image_model.class.name.underscore}_#{image_model.object_id}",
          'dynamic-form-event' => 'hideItembutton',
          'show-tooltip' => true
        }
      )
    end

    raw out
  end
end
