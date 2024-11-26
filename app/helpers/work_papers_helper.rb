module WorkPapersHelper
  def work_paper_show_change_history element_id
    link_to icon('fas', 'history'), "##{element_id}", {
      title: t('work_papers.history.show'),
      data:  { bs_toggle: 'collapse' },
      class: 'me-4'
    }
  end
end
