module ImageModelHelper
  def link_to_download_image model
    image_model = model.image_model

    if image_model && image_model.image? && image_model.image.cached?.blank?
      options = {
        class: 'btn btn-outline-secondary',
        title: image_model.identifier.titleize,
        data:  { ignore_unsaved_data: true }
      }

      link_to image_model.image.url, options do
        icon 'fas', 'download'
      end
    end
  end
end
