module OrganizationsHelper
  def organization_image_tag(thumb_name = :thumb)
    real_id = Organization.current_id
    Organization.current_id = @organization.id

    out = image_tag @organization.image_model.image.url(thumb_name),
      :size => @organization.image_model.image_size(thumb_name)

    Organization.current_id = real_id

    out
  end
end
