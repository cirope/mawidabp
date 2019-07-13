module TagsHelper
  def tag_kinds
    {
      control_objective: ControlObjective.model_name.human(count: 0),
      document:          Document.model_name.human(count: 0),
      finding:           Finding.model_name.human(count: 0),
      news:              News.model_name.human(count: 0),
      plan_item:         PlanItem.model_name.human(count: 0),
      review:            Review.model_name.human(count: 0)
    }.with_indifferent_access
  end

  def styles
    styles = %w(default primary success info warning danger)

    styles.map { |k| [t("tags.styles.#{k}"), k] }
  end

  def tags tags
    ActiveSupport::SafeBuffer.new.tap do |buffer|
      tags.each do |tag|
        buffer << content_tag(:span, class: "text-#{tag.style}") do
          content_tag :span, nil, class: "glyphicon glyphicon-#{tag.icon}", title: tag.name
        end
        buffer << ' '
      end
    end
  end

  def tag_shared_icon tag
    icon = content_tag :span, nil, class: 'glyphicon glyphicon-eye-open', title: t('activerecord.attributes.tag.shared')

    tag.shared ? icon : ''
  end

  def has_nested_tags? kind:
    Tag.list.non_roots.where(kind: kind).any?
  end

  def grouped_tag_options kind:
    options = {}

    Tag.list.roots.where(kind: kind).order(:name).each do |root_tag|
      if root_tag.children.any?
        options[root_tag.name] = root_tag.children.order(:name).map do |tag|
          [tag.name, tag.id]
        end
      else
        options[t('tags.list.childless')] ||= []

        options[t('tags.list.childless')] << [root_tag.name, root_tag.id]
      end
    end

    options
  end
end
