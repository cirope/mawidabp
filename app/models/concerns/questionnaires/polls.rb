module Questionnaires::Polls
  extend ActiveSupport::Concern

  included do
    has_many :polls, dependent: :destroy
  end

  def total_polls(answered = true)
    polls.where(answered: answered).count
  end
end
