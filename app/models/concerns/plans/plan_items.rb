module Plans::PlanItems
  extend ActiveSupport::Concern

  included do
    has_many :plan_items, -> { order :order_number }, dependent: :destroy
    has_many :resource_utilizations, through: :plan_items

    accepts_nested_attributes_for :plan_items, allow_destroy: true
  end

  def grouped_plan_items
    plan_items.group_by { |pi| pi.business_unit&.business_unit_type }
  end

  private

    def plan_items_on date
      if date == Time.zone.today
        plan_items
      else
        plan_items.where "#{PlanItem.quoted_table_name}.#{PlanItem.qcn 'start'} <= ?", date
      end
    end
end
