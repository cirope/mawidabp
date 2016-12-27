module PlanItems::Validations
  extend ActiveSupport::Concern

  included do
    validates :project, :order_number, presence: true
    validates :project, :predecessors, length: { maximum: 255 }, allow_nil: true, allow_blank: true
    validates :project, pdf_encoding: true
    validates :order_number, numericality: { only_integer: true }, allow_nil: true
    validates :start, timeliness: { type: :date }
    validates :end, timeliness: { type: :date, on_or_after: :start }
    validate :project_is_unique
    validate :dates_are_included_in_period
    validate :not_overloaded_or_allowed
    validate :related_plan_item_dates
    validate :predecessors_are_valid
  end

    private

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

          if predecessors.present?
            check_predecessors_dates_on plan_items
          end
        end
      end

      def predecessors_are_valid
        plan_items    = plan ? plan.plan_items.reject(&:marked_for_destruction?) : []
        order_numbers = plan_items.map &:order_number
        exist         = predecessors.all? do |predecessor|
          order_numbers.include?(predecessor)
        end
        are_previous  = predecessors.all? do |predecessor|
          predecessor < order_number
        end

        if predecessors && (!exist || !are_previous)
          errors.add :predecessors, :invalid
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

      def check_predecessors_dates_on plan_items
        predecessor_items = plan_items.select do |plan_item|
          predecessors.include?(plan_item.order_number)
        end

        if predecessor_items.any? { |pi| pi.end && start < pi.end }
          self.overloaded = true

          errors.add :start, :item_overload
        end

        if predecessor_items.any? { |pi| pi.end && self.end < pi.end }
          self.overloaded = true

          errors.add :end, :item_overload
        end
      end
end
