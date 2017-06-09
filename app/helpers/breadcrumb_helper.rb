module BreadcrumbHelper
  def show_breadcrumb?
    @auth_user && %w(welcome password).include?(controller_name)
  end

  def crumbs
    @auth_user ? crumbs_for(@auth_user.get_menu) : []
  end

  private

    def crumbs_for menu_items
      selected_modules = []
      controller_sym   = controller_path.split('/').first.to_sym

      menu_items.each do |item|
        has_controller = item.controllers.include? controller_sym
        met_conditions = item.conditions(controller_sym).blank? ||
          eval(item.conditions(controller_sym)) ||
          eval(item.conditions(controller_sym, false))

        if has_controller && met_conditions
          selected_modules << item
          selected_modules |= crumbs_for(item.children)
        end
      end

      @title ? selected_modules | [@title] : selected_modules
    end
end
