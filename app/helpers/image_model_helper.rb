module ImageModelHelper
  def link_to_download_image image_form
    image_model = image_form.object

    if image_model && image_model.image? && image_model.image.cached?.blank?
      options = {
        class: 'btn btn-outline-secondary',
        title: image_model.identifier.titleize,
        data:  { ignore_unsaved_data: true },
        id: "image_model_#{image_model.object_id}"
      }

      link_to image_model.image.url, options do
        icon 'fas', 'download'
      end
    end
  end
end
