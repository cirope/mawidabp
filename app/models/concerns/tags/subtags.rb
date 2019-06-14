module Tags::Subtags
  extend ActiveSupport::Concern

  included do
    acts_as_tree

    accepts_nested_attributes_for :children, allow_destroy: true
  end
end
