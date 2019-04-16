module MarkdownHelper
  def markdown(text)
    text.present? ? MARKDOWN_RENDERER.render(text).strip.html_safe : ''
  end

  def markdown_without_paragraph(text)
    styled_text = markdown text

    styled_text = styled_text[3..-1] if styled_text[0..2] == '<p>'
    styled_text = styled_text[0..-5] if styled_text[-4..-1] == '</p>'

    styled_text.html_safe
  end

  def markdown_help_link
    link = link_to 'markdown', '#markdown-help', data: { toggle: 'modal' }

    t '.markdown_help_html', link: link
  end
end
