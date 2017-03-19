class UpgradeDatetimeColumns < ActiveRecord::Migration[5.0]
  def change
    migrate_timestams

    change_column :file_models, :file_updated_at, :timestamp

    change_column :image_models, :image_updated_at, :timestamp

    change_column :login_records, :start, :timestamp
    change_column :login_records, :end, :timestamp

    change_column :news, :published_at, :timestamp

    change_column :notifications, :confirmation_date, :timestamp

    change_column :users, :last_access, :timestamp
    change_column :users, :hash_changed, :timestamp
  end

  def migrate_timestams
    tables = [
      :achievements,
      :answer_options,
      :answers,
      :benefits,
      :best_practices,
      :business_unit_findings,
      :business_unit_scores,
      :business_unit_types,
      :business_units,
      :comments,
      :conclusion_reviews,
      :control_objective_items,
      :control_objectives,
      :controls,
      :costs,
      :documents,
      :e_mails,
      :error_records,
      :file_models,
      :finding_answers,
      :finding_relations,
      :finding_review_assignments,
      :finding_user_assignments,
      :findings,
      :groups,
      :image_models,
      :ldap_configs,
      :news,
      :notification_relations,
      :notifications,
      :old_passwords,
      :organization_roles,
      :organizations,
      :periods,
      :plan_items,
      :plans,
      :polls,
      :privileges,
      :process_controls,
      :questionnaires,
      :questions,
      :related_user_relations,
      :resource_classes,
      :resource_utilizations,
      :resources,
      :review_user_assignments,
      :reviews,
      :roles,
      :settings,
      :taggings,
      :tags,
      :users,
      :work_papers,
      :workflow_items,
      :workflows
    ]

    tables.each do |table_name|
      change_column table_name, :created_at, :timestamp
      change_column table_name, :updated_at, :timestamp
    end

    change_column :login_records, :created_at, :timestamp
    change_column :versions, :created_at, :timestamp
  end
end
