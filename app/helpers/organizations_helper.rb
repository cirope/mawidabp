module OrganizationsHelper
  def organization_image_tag thumb_name: :thumb, model: :image_model
    scoped_organization_image model, thumb_name if image_persisted? model
  end

  def organization_image model = :image_model
    @organization.send "build_#{model}" unless @organization.send model

    @organization.send model
  end

  def organization_logo_style_options
    %w(default success info warning danger).map do |style|
      [t("organizations.logo_styles.#{style}"), style]
    end
  end

  def link_to_remove_authentication_configuration form
    configuration = form.object
    out           = ''

    if configuration.persisted?
      out << form.hidden_field(
        :_destroy,
        class: 'destroy',
        value: 0,
        id: "remove_#{configuration.class.name.underscore}_hidden_#{configuration.object_id}"
      )
      out << link_to(
        icon('fas', 'times-circle'), '#',
        title: t('label.delete'),
        class: 'float-right',
        data: {
          'dynamic-target' => "##{configuration.class.name.underscore}",
          'dynamic-form-event' => 'hideCard',
          'show-tooltip' => true
        }
      )
    end

    raw out
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
