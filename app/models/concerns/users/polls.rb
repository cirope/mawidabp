module Users::Polls
  extend ActiveSupport::Concern

  included do
    has_many :polls, dependent: :destroy
  end

  def list_unanswered_polls
    polls.list.answered false
  end

  def first_pending_poll
    list_unanswered_polls.order(:created_at).first
  end
end
