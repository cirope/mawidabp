module PlanItems::Comparable
  extend ActiveSupport::Concern

  def <=>(other)
    if other.kind_of?(PlanItem)
      order_number <=> other.order_number
    else
      -1
    end
  end

  def ==(other)
    if other.kind_of?(PlanItem)
      if new_record? && other.new_record?
        object_id == other.object_id
      else
        id == other.id
      end
    else
      -1
    end
  end
end
