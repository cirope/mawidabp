module Users::Polls
  extend ActiveSupport::Concern

  included do
    has_many :polls, dependent: :destroy
  end

  def first_pending_poll
    polls.list.answered(false).first
  end
end
