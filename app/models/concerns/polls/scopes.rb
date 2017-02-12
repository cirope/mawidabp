module Polls::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,      -> { where organization_id: Organization.current_id }
    scope :pollables, -> { where.not pollable_id: nil }
  end

  module ClassMethods
    def between_dates from, to
      where created_at: from..to
    end

    def by_questionnaire questionnaire_id
      where questionnaire_id: questionnaire_id
    end

    def answered answered
      where answered: answered
    end

    def by_affected_user affected_user_id, only_all: false
      if only_all
        where affected_user_id: nil
      elsif affected_user_id
        where affected_user_id: affected_user_id
      else
        all
      end
    end
  end
end
