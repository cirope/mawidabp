module MenuHelper
  def show_menu?
    @auth_user && @auth_user.is_enable? &&
      ((@auth_user.password && current_organization) ||
       current_organization && current_organization.ldap_config)
  end

  def show_logout?
    @auth_user && @auth_user.password
  end
end
