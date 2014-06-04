module Users::Tree
  extend ActiveSupport::Concern

  included do
    acts_as_tree foreign_key: 'manager_id',
      readonly: true,
      order: "#{table_name}.last_name ASC, #{table_name}.name ASC",
      dependent: :nullify
  end
end
