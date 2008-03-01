module OrganizationsHelper
  def image_logo_tag(thumb_name = :thumb)
    image_model = @organization.image_model
    
    image_tag image_model.public_filename(thumb_name),
      :size => image_model.thumb(thumb_name).image_size
  end

  def business_unit_type_text(type)
    content_tag(:span, business_unit_type_name_for(type), :class => :bold)
  end

  def business_unit_type_name_for(type)
    t "organization.business_unit_#{BusinessUnit::TYPES.invert[type]}.type"
  end
end