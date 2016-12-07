module NewsHelper
  def markdown_help_link
    link = link_to 'markdown', '#markdown-help', data: { toggle: 'modal' }

    t '.markdown_help_html', link: link
  end
end
