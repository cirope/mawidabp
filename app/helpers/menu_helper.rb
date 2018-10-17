module MenuHelper
  def show_menu?
    @auth_user && @auth_user.is_enable? &&
      ((@auth_user.password && current_organization) ||
       current_organization && current_organization.ldap_config)
  end

  def show_logout?
    @auth_user && @auth_user.password
  end

  def show_unanswered_poll_link
    count = @auth_user.list_unanswered_polls.count

    if count > 0
      poll  = @auth_user.first_pending_poll
      title = t 'polls.has_unanswered', count: count
      path  = edit_poll_path poll, token: poll.access_token
      link  = link_to path, title: title do
        content_tag :span, class: 'text-primary' do
          content_tag :span, nil, class: 'glyphicon glyphicon-list-alt'
        end
      end

      content_tag :li, link
    end
  end
end
