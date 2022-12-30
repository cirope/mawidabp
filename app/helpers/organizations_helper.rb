module OrganizationsHelper
  def organization_logo_style_options
    %w(default success info warning danger).map do |style|
      [t("organizations.logo_styles.#{style}"), style]
    end
  end
end
