module HelpContentsHelper
  def help_content_tree_for(help_content)
    list_text = String.new.html_safe

    unless help_content.try(:help_items).blank?
      help_content.help_items.each do |help_item|
        edit_link = link_to(help_item.name,
          show_content_help_content_path(help_item),
          :class => (@help_item.try(:id) == help_item.id ? "bold selected" : :bold))
        list_text << content_tag(:li, edit_link + help_item_list(help_item))
      end
    end

    list_text.blank? ? list_text : content_tag(:ul, list_text)
  end

  def help_item_list(parent)
    list_text = String.new.html_safe

    unless parent.try(:children).blank?
      parent.children.each do |child|
        show_or_hide_link = link_to_show_hide_help_item(child)
        edit_link = link_to(child.name, show_content_help_content_path(child),
          :class => (:selected if @help_item.try(:id) == child.id))
        list_text << content_tag(:li, raw(show_or_hide_link.to_s + edit_link +
            help_item_list(child)))
      end
    end

    list_text.blank? ? list_text : content_tag(:div,
      content_tag(:ul, list_text),
      :id => "help_item_#{parent.id}",
      :style => (parent.is_or_include?(@help_item.try(:id)) ?
          nil : 'display: none;')
    )
  end

  def link_to_show_hide_help_item(help_item)
    unless help_item.try(:children).blank?
      link_to_show_hide("help_item_#{help_item.id}",
        t(:'help_item.show_help_item_children'),
        t(:'help_item.hide_help_item_children'),
        help_item.is_or_include?(params[:id].try(:to_i)))
    end
  end
end