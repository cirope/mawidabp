module Findings::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,              -> { where organization_id: Current.organization&.id }
    scope :sort_by_code,      -> { order review_code: :asc }
    scope :sort_for_review,   -> { order *review_sort_options }
    scope :with_achievements, -> { includes(:achievements).where.not achievements: { finding_id: nil } }
  end

  module ClassMethods
    def group_list
      organization_ids = Organization.where(group_id: Current.group&.id).pluck('id')

      where organization_id: organization_ids
    end

    def list_for_report
      # TODO: we do it this way so we can serialize it
      conditions = []
      parameters = {}
      ids        = list_with_final_review.or(
        list_without_final_review.with_repeated
      ).pluck('id')

      ids.each_slice(1000).with_index do |finding_ids, i|
        conditions << "#{quoted_table_name}.#{qcn 'id'} IN (:ids_#{i})"
        parameters[:"ids_#{i}"] = finding_ids
      end

      includes(review: :conclusion_final_review).where(
        conditions.map { |c| "(#{c})" }.join(' OR '), parameters
      )
    end

    def list_with_final_review
      includes(control_objective_item: :review).
        list.
        where.not(ConclusionReview.table_name => { review_id: nil }).
        where(plan_item: PlanItem.allowed_by_business_units)
        references(:conclusion_reviews).
        where(conclusion_reviews: { type: ConclusionFinalReview.name })
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
      identifications = identification.split(SEARCH_OR_REGEXP).reject(&:blank?)
      conditions = []
      parameters = {}

      identifications.each_with_index do |identification, i|
        conditions << "LOWER(#{Review.quoted_table_name}.#{Review.qcn 'identification'}) LIKE :i_#{i}"

        parameters[:"i_#{i}"] = identification.mb_chars.downcase.strip
      end

      includes(:review).
        where(conditions.join(' OR '), parameters).
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
          "#{User.quoted_table_name}.#{User.qcn 'id'} IN (:user_id)",
          "#{FindingAnswer.quoted_table_name}.#{FindingAnswer.qcn 'user_id'} IN (:user_id)"
        ]

        includes(:users, :finding_answers).
          where(conditions.map { |c| "(#{c})" }.join(' OR '), user_id: Array(user_id)).
          references(:users, :finding_answers)
      else
        includes(:users).where(users: { id: user_id }).references(:users)
      end
    end

    def excluding_user_id user_id
      ids = includes(:users).where(users: { id: user_id }).references(:users).ids

      where.not id: ids
    end

    def by_issue_date operator, date, date_until = nil
      mask      = operator.downcase == 'between' && date_until ? '? AND ?' : '?'
      condition = "#{ConclusionFinalReview.quoted_table_name}.#{ConclusionFinalReview.qcn 'issue_date'} #{operator} #{mask}"

      includes(review: :conclusion_final_review).where condition, *[date, date_until].compact
    end

    def by_origination_date operator, date, date_until = nil
      mask      = operator.downcase == 'between' && date_until ? '? AND ?' : '?'
      condition = "#{quoted_table_name}.#{qcn 'origination_date'} #{operator} #{mask}"

      where condition, *[date, date_until].compact
    end

    def by_business_unit_ids business_unit_ids
      includes(review: :plan_item).
        where(plan_items: { business_unit_id: Array(business_unit_ids) }).
        references(:plan_items)
    end

    def by_business_unit_type business_unit_type_id
      includes(review: { plan_item: :business_unit }).
        where(business_units: { business_unit_type_id: business_unit_type_id }).
        references(:business_units)
    end

    def by_control_objective_tags *tags
      conditions = []
      parameters = {}

      tags.flatten.each_with_index do |tag, i|
        conditions << "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'}) LIKE :cot_#{i}"

        parameters[:"cot_#{i}"] = "%#{tag.downcase}%"
      end

      includes(control_objective: :tags).where(conditions.join(' OR '), parameters)
    end

    def by_wilcard_tags tags, negate: false
      conditions = []
      parameters = {}

      tags.flatten.each_with_index do |tag, i|
        conditions << "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'}) LIKE :wt_#{i}"

        parameters[:"wt_#{i}"] = "%#{tag.downcase}%"
      end

      if negate
        result  = all
        tag_ids = Tag.list.for_findings.where(
          conditions.join(' OR '), parameters
        ).ids

        search_by_tags_count(tags, tag_ids.size).ids.each_slice(900) do |n_ids|
          where.not(id: n_ids).ids.each_slice(900) do |ids|
            result = result.where id: ids
          end
        end

        result
      else
        includes(:tags).references(:tags).where conditions.join(' OR '), parameters
      end
    end

    def by_review_tags *tags
      conditions = []
      parameters = {}

      tags.flatten.each_with_index do |tag, i|
        conditions << "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'}) LIKE :rt_#{i}"

        parameters[:"rt_#{i}"] = "%#{tag.downcase}%"
      end

      includes(review: :tags).where(conditions.join(' OR '), parameters)
    end

    def by_tag_icon icon
      includes(:tags).references(:tags).where tags: { icon: icon }
    end

    def review_sort_options
      if ORDER_WEAKNESSES_ON_CONCLUSION_REVIEWS_BY == 'risk'
        [risk: :desc, review_code: :asc]
      else
        [risk: :desc, priority: :desc, review_code: :asc]
      end
    end

    private

      def search_by_tags_count tags, min_tag_count
        having = "COUNT(DISTINCT #{Tag.quoted_table_name}.#{Tag.qcn 'id'}) >= ?"
        query  = tags.join ' OR '

        ids = where(
          *[prepare_search(raw_query: query, columns: ['tags'])].flatten
        ).
        having(having, min_tag_count).
        group(:id).
        pluck 'id'

        where id: ids
      end
  end
end
