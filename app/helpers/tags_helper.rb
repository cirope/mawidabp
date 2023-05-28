module TagsHelper
  def tag_kinds
    {
      control_objective: ControlObjective.model_name.human(count: 0),
      document:          Document.model_name.human(count: 0),
      finding:           Finding.model_name.human(count: 0),
      news:              News.model_name.human(count: 0),
      plan_item:         PlanItem.model_name.human(count: 0),
      review:            Review.model_name.human(count: 0),
      user:              User.model_name.human(count: 0)
    }.with_indifferent_access
  end

  def styles
    styles = %w(secondary primary success info warning danger)

    styles.map { |k| [t("tags.styles.#{k}"), k] }
  end

  def tags tags
    ActiveSupport::SafeBuffer.new.tap do |buffer|
      tags.each do |tag|
        buffer << content_tag(:span, class: "text-#{tag.style}") do
          icon 'fas', tag.icon, title: tag.name
        end
        buffer << ' '
      end
    end
  end

  def tag_shared_icon tag
    icon = icon 'fas', 'eye', title: t('activerecord.attributes.tag.shared')

    tag.shared ? icon : ''
  end

  def has_nested_tags? kind:
    Tag.list.non_roots.where(kind: kind).any?
  end

  def grouped_tag_options kind:
    options = {}

    Tag.list.roots.where(kind: kind, obsolete: false).order(:name).each do |root_tag|
      if root_tag.children.any?
        children = root_tag.children.where(obsolete: false).order :name

        options[root_tag.name] = children.map { |tag| [tag.name, tag.id] }
      else
        options[t('tags.list.childless')] ||= []

        options[t('tags.list.childless')] << [root_tag.name, root_tag.id]
      end
    end

    options
  end

  def tags_options_collection kind:
    Array(TAG_OPTIONS[kind])
  end

  def tag_option_type option
    if option.end_with?('_from') || option.end_with?('_to')
      :date_picker
    elsif option.end_with? '_count'
      :integer
    else
      :boolean
    end
  end

  def tag_input_option form, tag
    tag_type   = tag_option_type(tag.last)
    input_html = {
      id:    "#{tag.last}_tag_options",
      name:  "tag[options][#{tag.last}]",
      value: @tag.options.to_h[tag.last],
    }

    input_html.merge!(checked: @tag.options.to_h[tag.last] == '1') if tag_type == :boolean

    form.input :options,
      as: tag_type,
      label: tag.first,
      input_html: input_html
  end
end
