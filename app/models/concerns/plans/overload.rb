module Plans::Overload
  extend ActiveSupport::Concern

  included do
    attr_accessor :allow_overload
  end

  def overloaded?
    plan_items.any? &:overloaded
  end

  def allow_overload?
    allow_overload == true ||
      (allow_overload.respond_to?(:to_i) && allow_overload.to_i != 0)
  end
end
