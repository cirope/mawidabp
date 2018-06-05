module Findings::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,              -> { where organization_id: Organization.current_id }
    scope :sort_by_code,      -> { order review_code: :asc }
    scope :sort_for_review,   -> { order risk: :desc, priority: :desc, review_code: :asc }
    scope :with_achievements, -> { includes(:achievements).where.not achievements: { finding_id: nil } }
  end

  module ClassMethods
    def group_list
      organization_ids = Organization.where(group_id: Group.current_id).pluck('id')

      where organization_id: organization_ids
    end

    def list_with_final_review
      includes(control_objective_item: :review).
        merge(Review.list_with_final_review)
    end

    def list_without_final_review
      includes(control_objective_item: :review).
        merge(Review.list_without_final_review)
    end

    def with_title title
      where "LOWER(#{quoted_table_name}.#{qcn 'title'}) LIKE ?", "%#{title.mb_chars.downcase}%"
    end

    def with_prefix prefix
      where("#{quoted_table_name}.#{qcn 'review_code'} LIKE ?", "#{prefix}%").
        order(review_code: :asc)
    end

    def finals final
      where final: final
    end

    def all_for_reallocation_with_review review
      includes(control_objective_item: :review).
        where(reviews: { id: review.id }, state: ::Finding::PENDING_STATUS).
        finals(false).
        references(:reviews)
    end

    def by_review identification
      includes(:review).
        where("LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'}) LIKE ?", "%#{identification.mb_chars.downcase}%").
        references(:reviews)
    end

    def by_project project
      includes(review: :plan_item).
        where("LOWER(#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'project'}) LIKE ?", "%#{project.mb_chars.downcase}%").
        references(:plan_items)
    end

    def by_process_control name
      includes(control_objective: :process_control).
        where("LOWER(#{ProcessControl.quoted_table_name}.#{ProcessControl.qcn 'name'}) LIKE ?", "%#{name.mb_chars.downcase}%").
        references(:process_controls)
    end

    def by_control_objective name
      includes(:control_objective).
        where("LOWER(#{ControlObjective.quoted_table_name}.#{ControlObjective.qcn 'name'}) LIKE ?", "%#{name.mb_chars.downcase}%").
        references(:control_objectives)
    end

    def by_user_id user_id, include_finding_answers: false
      if include_finding_answers
        conditions = [
          "#{User.quoted_table_name}.#{User.qcn 'id'} = :user_id",
          "#{FindingAnswer.quoted_table_name}.#{FindingAnswer.qcn 'user_id'} = :user_id"
        ]

        includes(:users, :finding_answers).
          where(conditions.map { |c| "(#{c})" }.join(' OR '), user_id: user_id).
          references(:users, :finding_answers)
      else
        includes(:users).where(users: { id: user_id }).references(:users)
      end
    end

    def by_issue_date operator, date, date_until = nil
      mask      = operator.downcase == 'between' && date_until ? '? AND ?' : '?'
      condition = "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} #{operator} #{mask}"

      includes(review: :conclusion_final_review).where condition, *[date, date_until].compact
    end
  end
end
