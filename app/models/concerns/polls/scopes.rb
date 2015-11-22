module Polls::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Organization.current_id }
    scope :between_dates, ->(from, to) {
      list.where('created_at BETWEEN :from AND :to', from: from, to: to)
    }
    scope :by_questionnaire, ->(questionnaire_id) {
      list.where questionnaire_id: questionnaire_id
    }
    scope :answered, ->(answered) { where answered: answered }
    scope :pollables, -> { where.not pollable_id: nil }
  end
end
