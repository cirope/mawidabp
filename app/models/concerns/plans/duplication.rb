module Plans::Duplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :allow_duplication
  end

  def has_duplication?
    plan_items.any? do |plan_item|
      errors         = plan_item.errors
      @taken_error ||= taken_error_for plan_item
      
      errors[:project].include? @taken_error
    end
  end

  def allow_duplication?
    allow_duplication == true ||
      (allow_duplication.respond_to?(:to_i) && allow_duplication.to_i != 0)
  end

  private

    def taken_error_for plan_item
      ::ActiveModel::Errors.new(plan_item).generate_message :project, :taken
    end
end
