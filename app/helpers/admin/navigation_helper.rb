module Admin
  module NavigationHelper
    def nav_link_class(path)
      classes = ["admin-nav-link"]
      if current_page?(path)
        classes << "active"
      elsif path == admin_dashboard_path && request.path == "/admin"
        classes << "active"
      elsif request.path.start_with?(path)
        classes << "active"
      end
      classes.join(" ")
    end
  end
end
