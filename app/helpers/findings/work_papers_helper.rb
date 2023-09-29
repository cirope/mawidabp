module Findings::WorkPapersHelper
  def show_status_work_paper work_paper
    status = work_paper.status
    result = work_paper_info_for status
    title  = t "work_papers.statuses.#{status}"

    icon 'fas fa-xl', result.last, title: title, class: result.first
  end

  def link_to_next_status_work_paper work_paper
    status = work_paper.next_status

    if work_paper.persisted? && status.present?
      result    = work_paper_info_for status

      icon_text = if @auth_user.auditor?
                    t "work_papers.statuses.auditor.next_to_#{work_paper.status}"
                  elsif @auth_user.supervisor? || @auth_user.manager?
                    t "work_papers.statuses.supervisor.next_to_#{work_paper.status}"
                  end

      link_to icon('fas fa-xl', result.last, icon_text, class: result.first),
        work_paper_url(work_paper),
        class: 'dropdown-item',
        data: {
          method: :put,
          remote: true,
          confirm: t('messages.confirmation')
        }
    end
  end

  private

    def work_paper_info_for status
      case status
        when 'pending', nil then ['text-default', 'file-circle-exclamation']
        when 'finished'     then ['text-info',    'file-circle-check']
        when 'revised'      then ['text-success', 'file-shield']
      end
    end
end
