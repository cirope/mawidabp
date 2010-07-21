module OrganizationsHelper
  def image_logo_tag(thumb_name = :thumb)
    image_model = @organization.image_model
    
    image_tag image_model.public_filename(thumb_name),
      :size => image_model.thumb(thumb_name).image_size
  end
end