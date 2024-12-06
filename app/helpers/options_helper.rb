module OptionsHelper
  def link_to_remove_option
    link_to(
      icon('fas', 'times-circle'), '#',
      title: t('label.delete'),
      data: { remove_option: true, show_tooltip: true },
      class: 'text-danger'
    )
  end
end
