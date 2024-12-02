module WorkPapers::Statuses
  extend ActiveSupport::Concern

  included do
    enum status: {
      pending:  'pending',
      finished: 'finished',
      revised:  'revised'
    }

    after_initialize :set_status
    after_update_commit :mark_as_pending, unless: :saved_change_to_status?
    after_commit :update_review_status
  end

  def update_status
    change_status_to next_status
  end

  def next_status
    if persisted?
      if current_user_is? :auditor?
        case status
        when 'pending'  then 'finished'
        when 'finished' then 'pending'
        end
      elsif current_user_is?(:supervisor?) || current_user_is?(:manager?)
        case status
        when 'finished' then 'revised'
        when 'revised'  then 'pending'
        end
      end
    end
  end

  def current_user_is? role
    owner.
      review.
        review_user_assignments.
          where(user: Current.user).any? &role
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
