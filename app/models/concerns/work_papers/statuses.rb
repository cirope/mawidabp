module WorkPapers::Statuses
  extend ActiveSupport::Concern

  included do
    enum status: {
      pending:  'pending',
      finished: 'finished',
      revised:  'revised'
    }

    before_validation :set_status
    after_update_commit :mark_as_pending, unless: :saved_change_to_status?
    after_commit :update_review_status
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

    def set_status
      self.status ||= 'pending'
    end

    def change_status_to new_status
      send "#{new_status}!"
    end

    def mark_as_pending
      pending! unless pending?
    end

    def update_review_status
      if review = owner.review
        review.updated_from_work_paper = true

        review.update_status status
      end
    end
end
