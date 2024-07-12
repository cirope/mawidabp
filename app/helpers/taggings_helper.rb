module TaggingsHelper
  def tagging_item tagging
    tag = tagging.tag

    content_tag :li do
      content_tag :span, class: "badge bg-#{tag.style}" do
        raw "#{icon 'fas', tag.icon} #{h tag}"
      end
    end
  end
end
