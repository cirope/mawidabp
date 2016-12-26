module Plans::Clone
  extend ActiveSupport::Concern

  def clone_from(other)
    diff_in_years = diff_in_years_for period, other.period

    other.plan_items.each do |plan_item|
      attributes = plan_item_attributes_for plan_item, diff_in_years

      plan_items.build attributes
    end

    self.allow_overload    = true
    self.allow_duplication = true
  end

  private

    def diff_in_years_for period, other_period
      period ? (period.start.year - other_period.start.year).years : 0
    end

    def plan_item_attributes_for plan_item, diff_in_years
      attributes = plan_item.attributes.merge(
        'id'                               => nil,
        'resource_utilizations_attributes' => resource_utilizations_attributes_for(plan_item)
      ).with_indifferent_access

      complete_start_and_end_attributes attributes, diff_in_years
    end

    def resource_utilizations_attributes_for plan_item
      plan_item.resource_utilizations.map do |resource_utilization|
        resource_utilization.attributes.merge 'id' => nil
      end
    end

    def complete_start_and_end_attributes attributes, diff_in_years
      if attributes[:start]
        item_start = attributes[:start] = attributes[:start] + diff_in_years
      end

      if attributes[:end]
        item_end = attributes[:end] = attributes[:end] + diff_in_years
      end

      if period
        attributes[:start] = period.start unless period.contains? item_start
        attributes[:end]   = period.end   unless period.contains? item_end
      end

      attributes
    end
end
