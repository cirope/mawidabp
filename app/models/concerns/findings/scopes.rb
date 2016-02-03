module Findings::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,            -> { where organization_id: Organization.current_id }
    scope :sort_by_code,    -> { order review_code: :asc }
    scope :sort_for_review, -> { order risk: :desc, priority: :desc, review_code: :asc }
  end

  module ClassMethods
    def group_list
      organization_ids = Organization.where(group_id: Group.current_id).pluck('id')

      where organization_id: organization_ids
    end

    def with_title title
      where "#{quoted_table_name}.#{qcn 'title'} LIKE ?", "%#{title}%"
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
  end
end
