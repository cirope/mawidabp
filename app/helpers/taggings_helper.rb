module TaggingsHelper
  def tagging_item tagging
    tag  = tagging.tag
    icon = content_tag :span, nil, class: "glyphicon glyphicon-#{tag.icon}"

    content_tag :li do
      content_tag :span, class: "label label-#{tag.style}" do
         icon + ' ' + tag.to_s
      end
    end
  end
end
