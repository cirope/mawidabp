module WorkPapers::Statuses
  extend ActiveSupport::Concern

  included do
    enum status: {
      pending:  'pending',
      finished: 'finished',
      revised:  'revised'
    }
  end

  def update_status
    change_status_to next_status
  end

  def next_status
    if Current.user.auditor?
      case status
      when 'pending'  then 'finished'
      when 'finished' then 'pending'
      end
    elsif Current.user.supervisor? || Current.user.manager?
      case status
      when 'finished' then 'revised'
      when 'revised'  then 'pending'
      end
    end
  end

  private

    def change_status_to new_status
      send "#{new_status}!"
    end
end
