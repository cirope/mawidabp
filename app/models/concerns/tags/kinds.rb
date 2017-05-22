module Tags::Kinds
  extend ActiveSupport::Concern

  included do
    KINDS = %w(control_objective document finding news plan_item review)
  end
end
