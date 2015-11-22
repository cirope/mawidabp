module Users::Tree
  extend ActiveSupport::Concern

  included do
    acts_as_tree foreign_key: 'manager_id',
      readonly: true,
      order: "#{quoted_table_name}.#{qcn('last_name')} ASC, #{quoted_table_name}.#{qcn('name')} ASC",
      dependent: :nullify
  end
end
