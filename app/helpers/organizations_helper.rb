module OrganizationsHelper
  def image_logo_tag(thumb_name = :thumb)
    image_tag @organization.image_model.image.url(thumb_name),
      :size => @organization.image_model.image_size(thumb_name)
  end
end