class AddForeignKeys < ActiveRecord::Migration
  def self.up
    # Tabla users
    add_foreign_key :users, :resources, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :users, :users, :column => :manager_id,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla login_records
    add_foreign_key :login_records, :users, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :login_records, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla error_records
    add_foreign_key :error_records, :users, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :error_records, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla privileges
    add_foreign_key :privileges, :roles, :options => FOREIGN_KEY_OPTIONS

    # Tabla roles
    add_foreign_key :roles, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla old_passwords
    add_foreign_key :old_passwords, :users, :options => FOREIGN_KEY_OPTIONS

    # Tabla organizations
    add_foreign_key :organizations, :groups, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :organizations, :image_models, :options => FOREIGN_KEY_OPTIONS

    # Tabla work_papers
    add_foreign_key :work_papers, :file_models, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :work_papers, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla business_units
    add_foreign_key :business_units, :business_unit_types,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla findings
    add_foreign_key :findings, :control_objective_items, :options => FOREIGN_KEY_OPTIONS

    # Tabla periods
    add_foreign_key :periods, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla best_practices
    add_foreign_key :best_practices, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla process_controls
    add_foreign_key :process_controls, :best_practices, :options => FOREIGN_KEY_OPTIONS

    # Tabla control_objectives
    add_foreign_key :control_objectives, :process_controls,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla procedure_control_subitems
    add_foreign_key :procedure_control_subitems, :control_objectives,
      :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :procedure_control_subitems, :procedure_control_items,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla procedure_control_items
    add_foreign_key :procedure_control_items, :process_controls,
      :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :procedure_control_items, :procedure_controls,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla procedure_controls
    add_foreign_key :procedure_controls, :periods, :options => FOREIGN_KEY_OPTIONS

    # Tabla resource_classes
    add_foreign_key :resource_classes, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla resources
    add_foreign_key :resources, :resource_classes, :options => FOREIGN_KEY_OPTIONS

    # Tabla plan_items
    add_foreign_key :plan_items, :plans, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :plan_items, :business_units, :options => FOREIGN_KEY_OPTIONS

    # Tabla plans
    add_foreign_key :plans, :periods, :options => FOREIGN_KEY_OPTIONS

    # Tabla control_objective_items
    add_foreign_key :control_objective_items, :control_objectives,
      :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :control_objective_items, :reviews, :options => FOREIGN_KEY_OPTIONS

    # Tabla reviews
    add_foreign_key :reviews, :periods, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :reviews, :plan_items, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :reviews, :file_models, :options => FOREIGN_KEY_OPTIONS

    # Tabla conclusion_reviews
    add_foreign_key :conclusion_reviews, :reviews, :options => FOREIGN_KEY_OPTIONS

    # Tabla workflow_items
    add_foreign_key :workflow_items, :workflows, :options => FOREIGN_KEY_OPTIONS

    # Tabla workflows
    add_foreign_key :workflows, :reviews, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :workflows, :periods, :options => FOREIGN_KEY_OPTIONS

    # Tabla finding_answers
    add_foreign_key :finding_answers, :findings, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :finding_answers, :users, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :finding_answers, :file_models, :options => FOREIGN_KEY_OPTIONS

    # Tabla versions
    add_foreign_key :versions, :organizations, :options => FOREIGN_KEY_OPTIONS

    # Tabla review_user_assignments
    add_foreign_key :review_user_assignments, :reviews, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :review_user_assignments, :users, :options => FOREIGN_KEY_OPTIONS

    # Tabla notifications
    add_foreign_key :notifications, :users, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :notifications, :users, :column => :user_who_confirm_id,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla notification_relations
    add_foreign_key :notification_relations, :notifications,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla help_items
    add_foreign_key :help_items, :help_contents, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :help_items, :help_items, :column => :parent_id,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla costs
    add_foreign_key :costs, :users, :options => FOREIGN_KEY_OPTIONS

    # Tabla organization_roles
    add_foreign_key :organization_roles, :organizations, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :organization_roles, :users, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :organization_roles, :roles, :options => FOREIGN_KEY_OPTIONS

    # Tabla comments
    add_foreign_key :comments, :users, :options => FOREIGN_KEY_OPTIONS

    # Tabla detracts
    add_foreign_key :detracts, :organizations, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :detracts, :users, :options => FOREIGN_KEY_OPTIONS

    # Tabla finding_relations
    add_foreign_key :finding_relations, :findings, :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :finding_relations, :findings,
      :column => :related_finding_id, :options => FOREIGN_KEY_OPTIONS

    # Tabla business_unit_types
    add_foreign_key :business_unit_types, :organizations,
      :options => FOREIGN_KEY_OPTIONS

    # Tabla finding_user_assignments
    add_foreign_key :finding_user_assignments, :findings,
      :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :finding_user_assignments, :users, :options => FOREIGN_KEY_OPTIONS

    # Tabla finding_review_assignments
    add_foreign_key :finding_review_assignments, :findings,
      :options => FOREIGN_KEY_OPTIONS
    add_foreign_key :finding_review_assignments, :reviews, :options => FOREIGN_KEY_OPTIONS
  end

  def self.down
    # Tabla users
    remove_foreign_key :users, :column => :manager_id
    remove_foreign_key :users, :column => :resource_id

    # Tabla login_records
    remove_foreign_key :login_records, :column => :user_id
    remove_foreign_key :login_records, :column => :organization_id

    # Tabla error_records
    remove_foreign_key :error_records, :column => :user_id
    remove_foreign_key :error_records, :column => :organization_id

    # Tabla privileges
    remove_foreign_key :privileges, :column => :role_id

    # Tabla roles
    remove_foreign_key :roles, :column => :organization_id

    # Tabla old_passwords
    remove_foreign_key :old_passwords, :column => :user_id

    # Tabla organizations
    remove_foreign_key :organizations, :column => :group_id
    remove_foreign_key :organizations, :column => :image_model_id

    # Tabla work_papers
    remove_foreign_key :work_papers, :column => :file_model_id
    remove_foreign_key :work_papers, :column => :organization_id

    # Tabla business_units
    remove_foreign_key :business_units, :column => :business_unit_type_id

    # Tabla findings
    remove_foreign_key :findings, :column => :control_objective_item_id

    # Tabla periods
    remove_foreign_key :periods, :column => :organization_id

    # Tabla best_practices
    remove_foreign_key :best_practices, :column => :organization_id

    # Tabla process_controls
    remove_foreign_key :process_controls, :column => :best_practice_id

    # Tabla control_objectives
    remove_foreign_key :control_objectives, :column => :process_control_id

    # Tabla procedure_control_subitems
    remove_foreign_key :procedure_control_subitems,
      :column => :control_objective_id
    remove_foreign_key :procedure_control_subitems,
      :column => :procedure_control_item_id

    # Tabla procedure_control_items
    remove_foreign_key :procedure_control_items, :column => :process_control_id
    remove_foreign_key :procedure_control_items,
      :column => :procedure_control_id

    # Tabla procedure_controls
    remove_foreign_key :procedure_controls, :column => :period_id

    # Tabla resource_classes
    remove_foreign_key :resource_classes, :column => :organization_id

    # Tabla resources
    remove_foreign_key :resources, :column => :resource_class_id

    # Tabla plan_items
    remove_foreign_key :plan_items, :column => :plan_id
    remove_foreign_key :plan_items, :column => :business_unit_id

    # Tabla plans
    remove_foreign_key :plans, :column => :period_id

    # Tabla control_objective_items
    remove_foreign_key :control_objective_items,
      :column => :control_objective_id
    remove_foreign_key :control_objective_items, :column => :review_id

    # Tabla reviews
    remove_foreign_key :reviews, :column => :period_id
    remove_foreign_key :reviews, :column => :plan_item_id
    remove_foreign_key :reviews, :column => :file_model_id

    # Tabla conclusion_reviews
    remove_foreign_key :conclusion_reviews, :column => :review_id

    # Tabla workflow_items
    remove_foreign_key :workflow_items, :column => :workflow_id

    # Tabla workflows
    remove_foreign_key :workflows, :column => :review_id
    remove_foreign_key :workflows, :column => :period_id

    # Tabla finding_answers
    remove_foreign_key :finding_answers, :column => :finding_id
    remove_foreign_key :finding_answers, :column => :user_id
    remove_foreign_key :finding_answers, :column => :file_model_id

    # Tabla versions
    remove_foreign_key :versions, :column => :organization_id

    # Tabla review_user_assignments
    remove_foreign_key :review_user_assignments, :column => :review_id
    remove_foreign_key :review_user_assignments, :column => :user_id

    # Tabla notifications
    remove_foreign_key :notifications, :column => :user_id
    remove_foreign_key :notifications, :column => :user_who_confirm_id

    # Tabla notification_relations
    remove_foreign_key :notification_relations, :column => :notification_id

    # Tabla help_items
    remove_foreign_key :help_items, :column => :help_content_id
    remove_foreign_key :help_items, :column => :parent_id

    # Tabla costs
    remove_foreign_key :costs, :column => :user_id

    # Tabla organization_roles
    remove_foreign_key :organization_roles, :column => :organization_id
    remove_foreign_key :organization_roles, :column => :user_id
    remove_foreign_key :organization_roles, :column => :role_id

    # Tabla comments
    remove_foreign_key :comments, :column => :user_id

    # Tabla detracts
    remove_foreign_key :detracts, :column => :organization_id
    remove_foreign_key :detracts, :column => :user_id

    # Tabla finding_relations
    remove_foreign_key :finding_relations, :column => :finding_id
    remove_foreign_key :finding_relations, :column => :related_finding_id

    # Tabla business_unit_types
    remove_foreign_key :business_unit_types, :column => :organization_id

    # Tabla finding_user_assignments
    remove_foreign_key :finding_user_assignments, :column => :finding_id
    remove_foreign_key :finding_user_assignments, :column => :user_id

    # Tabla finding_review_assignments
    remove_foreign_key :finding_review_assignments, :column => :finding_id
    remove_foreign_key :finding_review_assignments, :column => :review_id
  end
end
