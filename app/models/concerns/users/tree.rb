module Users::Tree
  extend ActiveSupport::Concern

  included do
    extend ActsAsTree::TreeWalker

    acts_as_tree(
      foreign_key: 'manager_id',
      readonly:    true,
      order:       { last_name: :asc },
      dependent:   :nullify
    )
  end

  module ClassMethods
    def deepest_level
      result = 0

      walk_tree { |user, level| result = level if level > result }

      result
    end
  end
end
