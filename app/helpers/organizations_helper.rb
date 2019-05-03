module OrganizationsHelper
  def organization_image_tag thumb_name: :thumb, model: :image_model
    scoped_organization_image model, thumb_name if image_persisted? model
  end

  def organization_image model = :image_model
    @organization.send "build_#{model}" unless @organization.send model

    @organization.send model
  end

  private

    def image_persisted? model
      @organization.send(model) && !@organization.send(model).image_cache
    end

    def scoped_organization_image model, thumb_name
      Fiber.new do
        Current.organization = @organization

        image_tag @organization.send(model).image.url(thumb_name),
          size: @organization.send(model).image_size(thumb_name),
          alt: 'Logo'
      end.resume
    end
end
