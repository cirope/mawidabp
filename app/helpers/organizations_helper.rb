module OrganizationsHelper
  def organization_image_tag(thumb_name = :thumb)
    real_id = Organization.current_id
    Organization.current_id = @organization.id

    out = image_tag @organization.image_model.image.url(thumb_name),
      :size => @organization.image_model.image_size(thumb_name)

    Organization.current_id = real_id

    out
  end

  def kind_field(form)
    collection = ORGANIZATION_KINDS.collect do |kind|
      [t("activerecord.attributes.organization.kind_options.#{kind}"), kind]
    end

    form.input :kind, collection: collection, prompt: true
  end
end
