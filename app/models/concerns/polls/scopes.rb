module Polls::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,      -> { where organization_id: Current.organization_id }
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

    def answer_option option
      left_joins(answers: :answer_option).
        references(:answer_options).
        where(answer_options: { option: option })
    end

    def by_user user_id, include_reviews: false, only_all: false
      result = by_affected_user(user_id, only_all: only_all)

      if include_reviews
        result = result.
          joins(conclusion_review: { review: :review_user_assignments }).
          references(:review_user_assignments). # Just to be "OR compatible"
          or by_review_user(user_id)
      end

      result.distinct
    end

    def by_review_user user_id
      joins(conclusion_review: { review: :review_user_assignments }).
        by_affected_user(nil, only_all: true).
        where(review_user_assignments: { user_id: user_id })
    end

    def by_affected_user affected_user_id, only_all: false
      if only_all
        where about_id: nil
      elsif affected_user_id
        where about_id: affected_user_id, about_type: User.name
      else
        all
      end
    end
  end
end
