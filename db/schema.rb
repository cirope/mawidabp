# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20171011194548) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "achievements", id: :serial, force: :cascade do |t|
    t.integer "benefit_id", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.text "comment"
    t.integer "finding_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["benefit_id"], name: "index_achievements_on_benefit_id"
    t.index ["finding_id"], name: "index_achievements_on_finding_id"
  end

  create_table "answer_options", id: :serial, force: :cascade do |t|
    t.text "option"
    t.integer "question_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["option", "question_id"], name: "index_answer_options_on_option_and_question_id"
  end

  create_table "answers", id: :serial, force: :cascade do |t|
    t.text "comments"
    t.string "type", limit: 255
    t.integer "question_id"
    t.integer "poll_id"
    t.integer "lock_version", default: 0
    t.text "answer"
    t.integer "answer_option_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["poll_id"], name: "index_answers_on_poll_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["type", "id"], name: "index_answers_on_type_and_id"
  end

  create_table "benefits", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "kind", limit: 255, null: false
    t.integer "organization_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["organization_id"], name: "index_benefits_on_organization_id"
  end

  create_table "best_practices", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "obsolete", default: false
    t.boolean "shared", default: false, null: false
    t.integer "group_id", null: false
    t.index ["created_at"], name: "index_best_practices_on_created_at"
    t.index ["group_id"], name: "index_best_practices_on_group_id"
    t.index ["obsolete"], name: "index_best_practices_on_obsolete"
    t.index ["organization_id"], name: "index_best_practices_on_organization_id"
  end

  create_table "business_unit_findings", id: :serial, force: :cascade do |t|
    t.integer "business_unit_id"
    t.integer "finding_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["business_unit_id"], name: "index_business_unit_findings_on_business_unit_id"
    t.index ["finding_id"], name: "index_business_unit_findings_on_finding_id"
  end

  create_table "business_unit_scores", id: :serial, force: :cascade do |t|
    t.integer "design_score"
    t.integer "compliance_score"
    t.integer "sustantive_score"
    t.integer "business_unit_id"
    t.integer "control_objective_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["business_unit_id"], name: "index_business_unit_scores_on_business_unit_id"
    t.index ["control_objective_item_id"], name: "index_business_unit_scores_on_control_objective_item_id"
  end

  create_table "business_unit_types", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.boolean "external", default: false, null: false
    t.string "business_unit_label", limit: 255
    t.string "project_label", limit: 255
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["external"], name: "index_business_unit_types_on_external"
    t.index ["name"], name: "index_business_unit_types_on_name"
    t.index ["organization_id"], name: "index_business_unit_types_on_organization_id"
  end

  create_table "business_units", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "business_unit_type_id"
    t.index ["business_unit_type_id"], name: "index_business_unit_on_business_unit_type_id"
    t.index ["name"], name: "index_business_unit_on_name"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.text "comment"
    t.integer "commentable_id"
    t.string "commentable_type", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "conclusion_reviews", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.integer "review_id"
    t.date "issue_date"
    t.text "conclusion"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "applied_procedures"
    t.boolean "approved"
    t.date "close_date"
    t.integer "organization_id"
    t.string "summary"
    t.index ["close_date"], name: "index_conclusion_reviews_on_close_date"
    t.index ["issue_date"], name: "index_conclusion_reviews_on_issue_date"
    t.index ["organization_id"], name: "index_conclusion_reviews_on_organization_id"
    t.index ["review_id"], name: "index_conclusion_reviews_on_review_id"
    t.index ["summary"], name: "index_conclusion_reviews_on_summary"
    t.index ["type"], name: "index_conclusion_reviews_on_type"
  end

  create_table "control_objective_items", id: :serial, force: :cascade do |t|
    t.text "control_objective_text"
    t.integer "relevance"
    t.integer "design_score"
    t.integer "compliance_score"
    t.date "audit_date"
    t.text "auditor_comment"
    t.integer "control_objective_id"
    t.integer "review_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "finished"
    t.integer "sustantive_score"
    t.integer "order_number"
    t.boolean "exclude_from_score", default: false, null: false
    t.integer "organization_id"
    t.index ["control_objective_id"], name: "index_control_objective_items_on_control_objective_id"
    t.index ["organization_id"], name: "index_control_objective_items_on_organization_id"
    t.index ["review_id"], name: "index_control_objective_items_on_review_id"
  end

  create_table "control_objectives", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "order"
    t.integer "process_control_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "relevance"
    t.integer "risk"
    t.boolean "obsolete", default: false
    t.string "support"
    t.index ["obsolete"], name: "index_control_objectives_on_obsolete"
    t.index ["process_control_id"], name: "index_control_objectives_on_process_control_id"
  end

  create_table "controls", id: :serial, force: :cascade do |t|
    t.text "control"
    t.text "effects"
    t.text "compliance_tests"
    t.text "design_tests"
    t.integer "order"
    t.integer "controllable_id"
    t.string "controllable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "sustantive_tests"
    t.index ["controllable_type", "controllable_id"], name: "index_controls_on_controllable_type_and_controllable_id"
  end

  create_table "costs", id: :serial, force: :cascade do |t|
    t.text "description"
    t.decimal "cost", precision: 15, scale: 2
    t.integer "item_id"
    t.string "item_type", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "cost_type", limit: 255
    t.index ["cost_type"], name: "index_costs_on_cost_type"
    t.index ["item_type", "item_id"], name: "index_costs_on_item_type_and_item_id"
    t.index ["user_id"], name: "index_costs_on_user_id"
  end

  create_table "documents", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.boolean "shared", default: false, null: false
    t.integer "lock_version", default: 0
    t.integer "file_model_id"
    t.integer "organization_id"
    t.integer "group_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["file_model_id"], name: "index_documents_on_file_model_id"
    t.index ["group_id"], name: "index_documents_on_group_id"
    t.index ["name"], name: "index_documents_on_name"
    t.index ["organization_id"], name: "index_documents_on_organization_id"
    t.index ["shared"], name: "index_documents_on_shared"
  end

  create_table "e_mails", id: :serial, force: :cascade do |t|
    t.text "to"
    t.text "subject"
    t.text "body"
    t.text "attachments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.index ["created_at"], name: "index_e_mails_on_created_at"
    t.index ["organization_id"], name: "index_e_mails_on_organization_id"
  end

  create_table "error_records", id: :serial, force: :cascade do |t|
    t.text "data"
    t.integer "error"
    t.integer "user_id"
    t.integer "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_error_records_on_created_at"
    t.index ["organization_id"], name: "index_error_records_on_organization_id"
    t.index ["user_id"], name: "index_error_records_on_user_id"
  end

  create_table "file_models", id: :serial, force: :cascade do |t|
    t.string "file_file_name", limit: 255
    t.string "file_content_type", limit: 255
    t.integer "file_file_size"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "file_updated_at"
  end

  create_table "finding_answers", id: :serial, force: :cascade do |t|
    t.text "answer"
    t.integer "finding_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "file_model_id"
    t.date "commitment_date"
    t.index ["file_model_id"], name: "index_finding_answers_on_file_model_id"
    t.index ["finding_id"], name: "index_finding_answers_on_finding_id"
    t.index ["user_id"], name: "index_finding_answers_on_user_id"
  end

  create_table "finding_relations", id: :serial, force: :cascade do |t|
    t.integer "finding_id"
    t.integer "related_finding_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "description", limit: 255, null: false
    t.index ["finding_id"], name: "index_finding_relations_on_finding_id"
    t.index ["related_finding_id"], name: "index_finding_relations_on_related_finding_id"
  end

  create_table "finding_review_assignments", id: :serial, force: :cascade do |t|
    t.integer "finding_id"
    t.integer "review_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["finding_id", "review_id"], name: "index_finding_review_assignments_on_finding_id_and_review_id"
  end

  create_table "finding_user_assignments", id: :serial, force: :cascade do |t|
    t.integer "finding_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "process_owner", default: false
    t.string "finding_type"
    t.boolean "responsible_auditor"
    t.index ["finding_id", "finding_type", "user_id"], name: "index_finding_user_assignments_on_finding_id_finding_type_and_u"
    t.index ["finding_id", "finding_type"], name: "index_finding_user_assignments_on_finding_id_and_finding_type"
  end

  create_table "findings", id: :serial, force: :cascade do |t|
    t.string "type", limit: 255
    t.integer "control_objective_item_id"
    t.string "review_code", limit: 255
    t.text "description"
    t.text "answer"
    t.integer "state"
    t.date "solution_date"
    t.integer "lock_version", default: 0
    t.text "audit_recommendations"
    t.text "effect"
    t.integer "risk"
    t.integer "priority"
    t.date "follow_up_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "audit_comments"
    t.date "first_notification_date"
    t.date "confirmation_date"
    t.boolean "final"
    t.integer "parent_id"
    t.integer "notification_level", default: 0
    t.date "origination_date"
    t.integer "repeated_of_id"
    t.integer "highest_risk"
    t.integer "organization_id"
    t.string "title", limit: 255
    t.integer "progress"
    t.text "current_situation"
    t.boolean "current_situation_verified", default: false, null: false
    t.string "compliance"
    t.string "operational_risk"
    t.text "impact", default: [], null: false, array: true
    t.text "internal_control_components", default: [], null: false, array: true
    t.index ["control_objective_item_id"], name: "index_findings_on_control_objective_item_id"
    t.index ["created_at"], name: "index_findings_on_created_at"
    t.index ["final"], name: "index_findings_on_final"
    t.index ["first_notification_date"], name: "index_findings_on_first_notification_date"
    t.index ["follow_up_date"], name: "index_findings_on_follow_up_date"
    t.index ["organization_id"], name: "index_findings_on_organization_id"
    t.index ["parent_id"], name: "index_findings_on_parent_id"
    t.index ["repeated_of_id"], name: "index_findings_on_repeated_of_id"
    t.index ["state"], name: "index_findings_on_state"
    t.index ["title"], name: "index_findings_on_title"
    t.index ["type"], name: "index_findings_on_type"
    t.index ["updated_at"], name: "index_findings_on_updated_at"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "admin_email", limit: 255
    t.string "admin_hash", limit: 255
    t.text "description"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["admin_email"], name: "index_groups_on_admin_email", unique: true
    t.index ["admin_hash"], name: "index_groups_on_admin_hash", unique: true
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "image_models", id: :serial, force: :cascade do |t|
    t.string "image_file_name", limit: 255
    t.string "image_content_type", limit: 255
    t.integer "image_file_size"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "image_updated_at"
    t.integer "imageable_id", null: false
    t.string "imageable_type", null: false
    t.index ["imageable_type", "imageable_id"], name: "index_image_models_on_imageable_type_and_imageable_id"
  end

  create_table "ldap_configs", id: :serial, force: :cascade do |t|
    t.string "hostname", limit: 255, null: false
    t.integer "port", default: 389, null: false
    t.string "basedn", limit: 255, null: false
    t.string "login_mask", limit: 255, null: false
    t.string "username_attribute", limit: 255, null: false
    t.string "name_attribute", limit: 255, null: false
    t.string "last_name_attribute", limit: 255, null: false
    t.string "email_attribute", limit: 255, null: false
    t.string "function_attribute", limit: 255
    t.string "roles_attribute", limit: 255, null: false
    t.string "manager_attribute", limit: 255
    t.integer "organization_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "filter", limit: 255
    t.index ["organization_id"], name: "index_ldap_configs_on_organization_id"
  end

  create_table "login_records", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "data"
    t.datetime "start"
    t.datetime "end"
    t.datetime "created_at"
    t.integer "organization_id"
    t.index ["end"], name: "index_login_records_on_end"
    t.index ["organization_id"], name: "index_login_records_on_organization_id"
    t.index ["start"], name: "index_login_records_on_start"
    t.index ["user_id"], name: "index_login_records_on_user_id"
  end

  create_table "news", id: :serial, force: :cascade do |t|
    t.string "title", null: false
    t.text "description"
    t.text "body", null: false
    t.boolean "shared", default: false, null: false
    t.datetime "published_at", null: false
    t.integer "lock_version", default: 0
    t.integer "organization_id", null: false
    t.integer "group_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["group_id"], name: "index_news_on_group_id"
    t.index ["organization_id"], name: "index_news_on_organization_id"
    t.index ["published_at"], name: "index_news_on_published_at"
    t.index ["shared"], name: "index_news_on_shared"
  end

  create_table "notification_relations", id: :serial, force: :cascade do |t|
    t.integer "notification_id"
    t.integer "model_id"
    t.string "model_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["model_type", "model_id"], name: "index_notification_relations_on_model_type_and_model_id"
    t.index ["notification_id"], name: "index_notification_relations_on_notification_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.string "confirmation_hash", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "user_who_confirm_id"
    t.integer "status"
    t.text "notes"
    t.integer "lock_version", default: 0
    t.datetime "confirmation_date"
    t.index ["confirmation_hash"], name: "index_notifications_on_confirmation_hash", unique: true
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
    t.index ["user_who_confirm_id"], name: "index_notifications_on_user_who_confirm_id"
  end

  create_table "old_passwords", id: :serial, force: :cascade do |t|
    t.string "password", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["created_at"], name: "index_old_passwords_on_created_at"
    t.index ["user_id"], name: "index_old_passwords_on_user_id"
  end

  create_table "organization_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["organization_id"], name: "index_organization_roles_on_organization_id"
    t.index ["role_id"], name: "index_organization_roles_on_role_id"
    t.index ["user_id"], name: "index_organization_roles_on_user_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "prefix", limit: 255
    t.text "description"
    t.integer "image_model_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "group_id"
    t.boolean "corporate", default: false, null: false
    t.index ["corporate"], name: "index_organizations_on_corporate"
    t.index ["group_id"], name: "index_organizations_on_group_id"
    t.index ["image_model_id"], name: "index_organizations_on_image_model_id"
    t.index ["name"], name: "index_organizations_on_name"
    t.index ["prefix"], name: "index_organizations_on_prefix", unique: true
  end

  create_table "periods", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.date "start"
    t.date "end"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["end"], name: "index_periods_on_end"
    t.index ["name"], name: "index_periods_on_name"
    t.index ["organization_id"], name: "index_periods_on_organization_id"
    t.index ["start"], name: "index_periods_on_start"
  end

  create_table "plan_items", id: :serial, force: :cascade do |t|
    t.string "project", limit: 255
    t.date "start"
    t.date "end"
    t.integer "order_number"
    t.integer "plan_id"
    t.integer "business_unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["business_unit_id"], name: "index_plan_items_on_business_unit_id"
    t.index ["plan_id"], name: "index_plan_items_on_plan_id"
  end

  create_table "plans", id: :serial, force: :cascade do |t|
    t.integer "period_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_plans_on_organization_id"
    t.index ["period_id"], name: "index_plans_on_period_id"
  end

  create_table "polls", id: :serial, force: :cascade do |t|
    t.text "comments"
    t.boolean "answered", default: false
    t.integer "lock_version", default: 0
    t.integer "user_id", null: false
    t.integer "questionnaire_id"
    t.integer "pollable_id"
    t.string "pollable_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.string "access_token", limit: 255
    t.integer "affected_user_id"
    t.index ["affected_user_id"], name: "index_polls_on_affected_user_id"
    t.index ["organization_id"], name: "index_polls_on_organization_id"
    t.index ["pollable_id", "pollable_type"], name: "index_polls_on_pollable_id_and_pollable_type"
    t.index ["questionnaire_id"], name: "index_polls_on_questionnaire_id"
    t.index ["user_id"], name: "index_polls_on_user_id"
  end

  create_table "privileges", id: :serial, force: :cascade do |t|
    t.string "module", limit: 100
    t.boolean "read", default: false
    t.boolean "modify", default: false
    t.boolean "erase", default: false
    t.integer "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "approval", default: false
    t.index ["role_id"], name: "index_privileges_on_role_id"
  end

  create_table "process_controls", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "order"
    t.integer "best_practice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "obsolete", default: false
    t.index ["best_practice_id"], name: "index_process_controls_on_best_practice_id"
    t.index ["obsolete"], name: "index_process_controls_on_obsolete"
  end

  create_table "questionnaires", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.string "pollable_type", limit: 255
    t.string "email_subject", limit: 255
    t.string "email_link", limit: 255
    t.string "email_text", limit: 255
    t.string "email_clarification", limit: 255
    t.index ["name"], name: "index_questionnaires_on_name"
    t.index ["organization_id"], name: "index_questionnaires_on_organization_id"
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.integer "sort_order"
    t.integer "answer_type"
    t.text "question"
    t.integer "questionnaire_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["question", "questionnaire_id"], name: "index_questions_on_question_and_questionnaire_id"
  end

  create_table "related_user_relations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "related_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["user_id", "related_user_id"], name: "index_related_user_relations_on_user_id_and_related_user_id"
  end

  create_table "resource_classes", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "unit"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name"], name: "index_resource_classes_on_name"
    t.index ["organization_id"], name: "index_resource_classes_on_organization_id"
  end

  create_table "resource_utilizations", id: :serial, force: :cascade do |t|
    t.decimal "units", precision: 15, scale: 2
    t.integer "resource_consumer_id"
    t.string "resource_consumer_type", limit: 255
    t.integer "resource_id"
    t.string "resource_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["resource_consumer_id", "resource_consumer_type"], name: "resource_utilizations_consumer_consumer_type_idx"
    t.index ["resource_id", "resource_type"], name: "resource_utilizations_resource_resource_type_idx"
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.text "description"
    t.integer "resource_class_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["resource_class_id"], name: "index_resources_on_resource_class_id"
  end

  create_table "review_user_assignments", id: :serial, force: :cascade do |t|
    t.integer "assignment_type"
    t.integer "review_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean "include_signature", default: true, null: false
    t.boolean "owner", default: false, null: false
    t.index ["review_id", "user_id"], name: "index_review_user_assignments_on_review_id_and_user_id"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.string "identification", limit: 255
    t.text "description"
    t.integer "period_id"
    t.integer "plan_item_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "file_model_id"
    t.text "survey"
    t.integer "score"
    t.integer "top_scale"
    t.integer "achieved_scale"
    t.integer "organization_id"
    t.index ["file_model_id"], name: "index_reviews_on_file_model_id"
    t.index ["identification"], name: "index_reviews_on_identification"
    t.index ["organization_id"], name: "index_reviews_on_organization_id"
    t.index ["period_id"], name: "index_reviews_on_period_id"
    t.index ["plan_item_id"], name: "index_reviews_on_plan_item_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "role_type"
    t.index ["name"], name: "index_roles_on_name"
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255, null: false
    t.string "value", limit: 255, null: false
    t.text "description"
    t.integer "organization_id", null: false
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["name", "organization_id"], name: "index_settings_on_name_and_organization_id", unique: true
    t.index ["name"], name: "index_settings_on_name"
    t.index ["organization_id"], name: "index_settings_on_organization_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tag_id"], name: "index_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id"], name: "index_taggings_on_taggable_type_and_taggable_id"
  end

  create_table "tags", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.string "style", null: false
    t.integer "organization_id", null: false
    t.integer "lock_version", default: 0
    t.jsonb "options"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "shared", default: false, null: false
    t.integer "group_id", null: false
    t.string "icon", default: "tag", null: false
    t.index ["group_id"], name: "index_tags_on_group_id"
    t.index ["kind"], name: "index_tags_on_kind"
    t.index ["name"], name: "index_tags_on_name"
    t.index ["options"], name: "index_tags_on_options", using: :gin
    t.index ["organization_id"], name: "index_tags_on_organization_id"
    t.index ["shared"], name: "index_tags_on_shared"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "last_name", limit: 100
    t.string "language", limit: 10
    t.string "email", limit: 100
    t.string "user", limit: 30
    t.string "password", limit: 128
    t.date "password_changed"
    t.boolean "enable"
    t.integer "failed_attempts", default: 0
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "last_access"
    t.boolean "logged_in", default: false
    t.string "salt", limit: 255
    t.string "change_password_hash", limit: 255
    t.string "function", limit: 255
    t.integer "manager_id"
    t.boolean "group_admin", default: false
    t.text "notes"
    t.datetime "hash_changed"
    t.boolean "hidden", default: false
    t.index ["change_password_hash"], name: "index_users_on_change_password_hash", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["group_admin"], name: "index_users_on_group_admin"
    t.index ["hidden"], name: "index_users_on_hidden"
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["user"], name: "index_users_on_user"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.integer "item_id"
    t.string "item_type", limit: 255
    t.string "event", limit: 255, null: false
    t.integer "whodunnit"
    t.datetime "created_at"
    t.integer "organization_id"
    t.boolean "important"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["important"], name: "index_versions_on_important"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["organization_id"], name: "index_versions_on_organization_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "work_papers", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.string "code", limit: 255
    t.text "description"
    t.integer "file_model_id"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "number_of_pages"
    t.integer "owner_id"
    t.string "owner_type", limit: 255
    t.index ["file_model_id"], name: "index_work_papers_on_file_model_id"
    t.index ["organization_id"], name: "index_work_papers_on_organization_id"
    t.index ["owner_type", "owner_id"], name: "index_work_papers_on_owner_type_and_owner_id"
  end

  create_table "workflow_items", id: :serial, force: :cascade do |t|
    t.text "task"
    t.date "start"
    t.date "end"
    t.integer "order_number"
    t.integer "workflow_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["workflow_id"], name: "index_workflow_items_on_workflow_id"
  end

  create_table "workflows", id: :serial, force: :cascade do |t|
    t.integer "review_id"
    t.integer "period_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.index ["organization_id"], name: "index_workflows_on_organization_id"
    t.index ["period_id"], name: "index_workflows_on_period_id"
    t.index ["review_id"], name: "index_workflows_on_review_id"
  end

  add_foreign_key "achievements", "benefits", name: "achievements_benefit_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "achievements", "findings", name: "achievements_finding_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "benefits", "organizations", name: "benefits_organization_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practices", "groups", name: "best_practices_group_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practices", "organizations", name: "best_practices_organization_id_fk", on_delete: :restrict
  add_foreign_key "business_unit_findings", "business_units", name: "business_unit_findings_business_unit_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_findings", "findings", name: "business_unit_findings_finding_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_scores", "business_units", name: "business_unit_scores_business_unit_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_scores", "control_objective_items", name: "business_unit_scores_control_objective_item_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_types", "organizations", name: "business_unit_types_organization_id_fk", on_delete: :restrict
  add_foreign_key "business_units", "business_unit_types", name: "business_units_business_unit_type_id_fk", on_delete: :restrict
  add_foreign_key "comments", "users", name: "comments_user_id_fk", on_delete: :restrict
  add_foreign_key "conclusion_reviews", "reviews", name: "conclusion_reviews_review_id_fk", on_delete: :restrict
  add_foreign_key "control_objective_items", "control_objectives", name: "control_objective_items_control_objective_id_fk", on_delete: :restrict
  add_foreign_key "control_objective_items", "reviews", name: "control_objective_items_review_id_fk", on_delete: :restrict
  add_foreign_key "control_objectives", "process_controls", name: "control_objectives_process_control_id_fk", on_delete: :restrict
  add_foreign_key "costs", "users", name: "costs_user_id_fk", on_delete: :restrict
  add_foreign_key "documents", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "documents", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "documents", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "error_records", "organizations", name: "error_records_organization_id_fk", on_delete: :restrict
  add_foreign_key "error_records", "users", name: "error_records_user_id_fk", on_delete: :restrict
  add_foreign_key "finding_answers", "file_models", name: "finding_answers_file_model_id_fk", on_delete: :restrict
  add_foreign_key "finding_answers", "findings", name: "finding_answers_finding_id_fk", on_delete: :restrict
  add_foreign_key "finding_answers", "users", name: "finding_answers_user_id_fk", on_delete: :restrict
  add_foreign_key "finding_relations", "findings", column: "related_finding_id", name: "finding_relations_related_finding_id_fk", on_delete: :restrict
  add_foreign_key "finding_relations", "findings", name: "finding_relations_finding_id_fk", on_delete: :restrict
  add_foreign_key "finding_review_assignments", "findings", name: "finding_review_assignments_finding_id_fk", on_delete: :restrict
  add_foreign_key "finding_review_assignments", "reviews", name: "finding_review_assignments_review_id_fk", on_delete: :restrict
  add_foreign_key "finding_user_assignments", "findings", name: "finding_user_assignments_finding_id_fk", on_delete: :restrict
  add_foreign_key "finding_user_assignments", "users", name: "finding_user_assignments_user_id_fk", on_delete: :restrict
  add_foreign_key "findings", "control_objective_items", name: "findings_control_objective_item_id_fk", on_delete: :restrict
  add_foreign_key "findings", "findings", column: "repeated_of_id", name: "findings_repeated_of_id_fk", on_delete: :restrict
  add_foreign_key "ldap_configs", "organizations", name: "ldap_configs_organization_id_fk", on_update: :restrict, on_delete: :restrict
  add_foreign_key "login_records", "organizations", name: "login_records_organization_id_fk", on_delete: :restrict
  add_foreign_key "login_records", "users", name: "login_records_user_id_fk", on_delete: :restrict
  add_foreign_key "news", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "news", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notification_relations", "notifications", name: "notification_relations_notification_id_fk", on_delete: :restrict
  add_foreign_key "notifications", "users", column: "user_who_confirm_id", name: "notifications_user_who_confirm_id_fk", on_delete: :restrict
  add_foreign_key "notifications", "users", name: "notifications_user_id_fk", on_delete: :restrict
  add_foreign_key "old_passwords", "users", name: "old_passwords_user_id_fk", on_delete: :restrict
  add_foreign_key "organization_roles", "organizations", name: "organization_roles_organization_id_fk", on_delete: :restrict
  add_foreign_key "organization_roles", "roles", name: "organization_roles_role_id_fk", on_delete: :restrict
  add_foreign_key "organization_roles", "users", name: "organization_roles_user_id_fk", on_delete: :restrict
  add_foreign_key "organizations", "groups", name: "organizations_group_id_fk", on_delete: :restrict
  add_foreign_key "organizations", "image_models", name: "organizations_image_model_id_fk", on_delete: :restrict
  add_foreign_key "periods", "organizations", name: "periods_organization_id_fk", on_delete: :restrict
  add_foreign_key "plan_items", "business_units", name: "plan_items_business_unit_id_fk", on_delete: :restrict
  add_foreign_key "plan_items", "plans", name: "plan_items_plan_id_fk", on_delete: :restrict
  add_foreign_key "plans", "periods", name: "plans_period_id_fk", on_delete: :restrict
  add_foreign_key "polls", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "polls", "questionnaires", on_update: :restrict, on_delete: :restrict
  add_foreign_key "polls", "users", column: "affected_user_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "polls", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "privileges", "roles", name: "privileges_role_id_fk", on_delete: :restrict
  add_foreign_key "process_controls", "best_practices", name: "process_controls_best_practice_id_fk", on_delete: :restrict
  add_foreign_key "resource_classes", "organizations", name: "resource_classes_organization_id_fk", on_delete: :restrict
  add_foreign_key "resources", "resource_classes", name: "resources_resource_class_id_fk", on_delete: :restrict
  add_foreign_key "review_user_assignments", "reviews", name: "review_user_assignments_review_id_fk", on_delete: :restrict
  add_foreign_key "review_user_assignments", "users", name: "review_user_assignments_user_id_fk", on_delete: :restrict
  add_foreign_key "reviews", "file_models", name: "reviews_file_model_id_fk", on_delete: :restrict
  add_foreign_key "reviews", "periods", name: "reviews_period_id_fk", on_delete: :restrict
  add_foreign_key "reviews", "plan_items", name: "reviews_plan_item_id_fk", on_delete: :restrict
  add_foreign_key "roles", "organizations", name: "roles_organization_id_fk", on_delete: :restrict
  add_foreign_key "settings", "organizations", name: "settings_organization_id_fk", on_delete: :restrict
  add_foreign_key "taggings", "tags", on_update: :restrict, on_delete: :restrict
  add_foreign_key "tags", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "tags", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users", "users", column: "manager_id", name: "users_manager_id_fk", on_delete: :restrict
  add_foreign_key "work_papers", "file_models", name: "work_papers_file_model_id_fk", on_delete: :restrict
  add_foreign_key "work_papers", "organizations", name: "work_papers_organization_id_fk", on_delete: :restrict
  add_foreign_key "workflow_items", "workflows", name: "workflow_items_workflow_id_fk", on_delete: :restrict
  add_foreign_key "workflows", "periods", name: "workflows_period_id_fk", on_delete: :restrict
  add_foreign_key "workflows", "reviews", name: "workflows_review_id_fk", on_delete: :restrict
end
