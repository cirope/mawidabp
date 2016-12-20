module MarkdownHelper
  def markdown text
    MARKDOWN_RENDERER.render(text).html_safe
  end

  def markdown_help_link
    link = link_to 'markdown', '#markdown-help', data: { toggle: 'modal' }

    t '.markdown_help_html', link: link
  end
end
