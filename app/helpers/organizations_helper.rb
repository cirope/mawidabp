module OrganizationsHelper
  def organization_image_tag(thumb_name = :thumb)
    real_id = GlobalModelConfig.current_organization_id
    GlobalModelConfig.current_organization_id = @organization.id

    out = image_tag @organization.image_model.image.url(thumb_name),
      :size => @organization.image_model.image_size(thumb_name)

    GlobalModelConfig.current_organization_id = real_id

    out
  end
end