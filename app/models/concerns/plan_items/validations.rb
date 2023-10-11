module PlanItems::Validations
  extend ActiveSupport::Concern

  included do
    validates :project, :order_number, presence: true
    validates :project, length: { maximum: 255 }, allow_nil: true, allow_blank: true
    validates :project, pdf_encoding: true
    validates :order_number, numericality: { only_integer: true }, allow_nil: true
    validates :start, timeliness: { type: :date }
    validates :end, timeliness: { type: :date, on_or_after: :start }
    validates :risk_exposure, presence: true, if: :validate_extra_attributes?
    validates :scope, presence: true, if: :require_scope?
    validates :business_unit_type, presence: true, if: :validate_business_unit_type?
    validate :project_is_unique
    validate :dates_are_included_in_period
    validate :not_overloaded_or_allowed
    validate :related_plan_item_dates
    validate :uniqueness_auxiliar_business_unit_types
    validate :edit_business_unit
  end

    private

      def uniqueness_auxiliar_business_unit_types
        business_unit_types = []

        auxiliar_business_unit_types.each do |auxiliar_business_unit_type|
          if business_unit_types.include?(auxiliar_business_unit_type.business_unit_type.id)
            auxiliar_business_unit_type.errors.add(:business_unit_type_id, :taken)
            errors.add(:auxiliar_business_unit_types, :taken)
          else
            business_unit_types.push(auxiliar_business_unit_type.business_unit_type.id)
          end
        end
      end

      def project_is_unique
        unless plan&.allow_duplication?
          Array(plan&.plan_items).each do |pi|
            another_record = (!new_record? && pi.id != id) || (new_record? && pi.object_id != object_id)

            if another_record && pi.project == project && !pi.marked_for_destruction?
              errors.add :project, :taken
            end
          end
        end
      end

      def dates_are_included_in_period
        period = plan.period

        if period && start && !start.between?(period.start, period.end)
          errors.add :start, :out_of_period
        end

        if period && self.end && !self.end.between?(period.start, period.end)
          errors.add :end, :out_of_period
        end
      end

      def not_overloaded_or_allowed
        if plan && !plan.allow_overload?
          resource_table = build_resource_table_for plan

          human_resource_utilizations.each do |resource_utilization|
            check_for_overload resource_utilization, resource_table
          end
        end
      end

      def related_plan_item_dates
        if plan && !plan.allow_overload?
          plan_items = plan.plan_items.reject { |pi| pi.marked_for_destruction? }
        end
      end

      def build_resource_table_for plan
        result     = {}
        plan_items = plan.plan_items.reject &:marked_for_destruction?

        plan_items.each do |plan_item|
          if start && plan_item.start && plan_item.start < start
            plan_item.human_resource_utilizations.each do |resource_utilization|
              resource_id = resource_utilization.resource_id

              if resource_id && !resource_utilization.marked_for_destruction?
                result[resource_id] ||= []
                result[resource_id] << [plan_item.start, plan_item.end]
              end
            end
          end
        end

        result
      end

      def check_for_overload resource_utilization, resource_table
        resource_id = resource_utilization.resource_id

        if resource_id && !resource_utilization.marked_for_destruction?
          (resource_table[resource_id] || []).each do |start_date, end_date|
            if start_date && end_date && start.between?(start_date, end_date)
              self.overloaded = true

              errors.add :start, :resource_overload
            end

            if start_date && end_date && self.end.between?(start_date, end_date)
              self.overloaded = true

              errors.add :end, :resource_overload
            end
          end
        end
      end

      def validate_extra_attributes?
        SHOW_REVIEW_EXTRA_ATTRIBUTES
      end

      def require_scope?
        SHOW_REVIEW_EXTRA_ATTRIBUTES || USE_SCOPE_CYCLE
      end

      def validate_business_unit_type?
        Current.user&.business_unit_types&.list&.any?
      end

      def edit_business_unit
        if business_unit_id_changed? && !can_edit_business_unit?
          errors.add :business_unit,
                     :cannot_edit_business_unit,
                     memo_condition: SHOW_MEMOS ? I18n.t('plan_item.errors.cannot_edit_business_unit_for_memos_too') : ''
        end
      end
end
