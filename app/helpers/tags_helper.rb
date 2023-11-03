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

        options[root_tag.name] = children.map { |tag| [tag.name, tag.id, { "data-include-description" => root_tag.include_description? }] }
      else
        options[t('tags.list.childless')] ||= []

        options[t('tags.list.childless')] << [root_tag.name, root_tag.id, { "data-include-description" => root_tag.include_description? }]
      end
    end

    options
  end

  def tags_options_collection kind:
    tag_options = TAG_OPTIONS[kind].dup

    if kind == 'finding' && Current.conclusion_pdf_format == 'nbc'
      tag_options.merge! I18n.t('tags.options.origination_audit') => 'origination_audit'
    end

    Array tag_options
  end

  def tag_input_option form, tag, value
    option     = value.last
    input_html = {
      id:    "#{option}_tag_options",
      name:  "tag[options][#{option}]",
      value: tag.option_value(option),
    }

    input_html.merge!(checked: tag.option_value(option)) if tag.is_boolean?(option)

    form.input :options,
      as:         tag.option_type(option),
      label:      value.first,
      input_html: input_html
  end
end
