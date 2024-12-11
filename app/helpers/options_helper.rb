module OptionsHelper
  def link_to_add_option type
    link_to(
      t('options.scores.add'), options_path(type: type),
      data: { show_tooltip: true, remote: true, method: :post },
      class: 'btn btn-outline-secondary'
    )
  end

  def link_to_remove_option
    link_to(
      icon('fas', 'times-circle'), '#',
      title: t('options.scores.delete'),
      data: { remove_option: true, show_tooltip: true },
      class: 'text-danger'
    )
  end

  def options_errors_for object, type
    object.errors.select { |error| error.type == type.to_sym }
  end
end
