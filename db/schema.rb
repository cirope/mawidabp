# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20150427051208) do

  create_table "achievements", force: true do |t|
    t.integer  "benefit_id",                          null: false
    t.decimal  "amount",     precision: 15, scale: 2
    t.text     "comment"
    t.integer  "finding_id",                          null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "achievements", ["benefit_id"], name: "index_achievements_on_benefit_id"
  add_index "achievements", ["finding_id"], name: "index_achievements_on_finding_id"

  create_table "answer_options", force: true do |t|
    t.text     "option"
    t.integer  "question_id"
    t.integer  "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "answer_options", ["question_id"], name: "index_answer_options_on_question_id"

  create_table "answers", force: true do |t|
    t.text     "comments"
    t.string   "type"
    t.integer  "question_id"
    t.integer  "poll_id"
    t.integer  "lock_version",     default: 0
    t.text     "answer"
    t.integer  "answer_option_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "answers", ["poll_id"], name: "index_answers_on_poll_id"
  add_index "answers", ["question_id"], name: "index_answers_on_question_id"
  add_index "answers", ["type", "id"], name: "index_answers_on_type_and_id"

  create_table "benefits", force: true do |t|
    t.string   "name",            null: false
    t.string   "kind",            null: false
    t.integer  "organization_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "benefits", ["organization_id"], name: "index_benefits_on_organization_id"

  create_table "best_practices", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "organization_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "obsolete",        default: false
    t.boolean  "shared",          default: false
    t.integer  "group_id"
  end

  add_index "best_practices", ["created_at"], name: "index_best_practices_on_created_at"
  add_index "best_practices", ["group_id"], name: "index_best_practices_on_group_id"
  add_index "best_practices", ["obsolete"], name: "index_best_practices_on_obsolete"
  add_index "best_practices", ["organization_id"], name: "index_best_practices_on_organization_id"

  create_table "business_unit_findings", force: true do |t|
    t.integer  "business_unit_id"
    t.integer  "finding_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "business_unit_findings", ["business_unit_id"], name: "index_business_unit_findings_on_business_unit_id"
  add_index "business_unit_findings", ["finding_id"], name: "index_business_unit_findings_on_finding_id"

  create_table "business_unit_scores", force: true do |t|
    t.integer  "design_score"
    t.integer  "compliance_score"
    t.integer  "sustantive_score"
    t.integer  "business_unit_id"
    t.integer  "control_objective_item_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "business_unit_scores", ["business_unit_id"], name: "index_business_unit_scores_on_business_unit_id"
  add_index "business_unit_scores", ["control_objective_item_id"], name: "index_business_unit_scores_on_control_objective_item_id"

  create_table "business_unit_types", force: true do |t|
    t.string   "name"
    t.boolean  "external",            default: false, null: false
    t.string   "business_unit_label"
    t.string   "project_label"
    t.integer  "organization_id"
    t.integer  "lock_version",        default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "business_unit_types", ["external"], name: "index_business_unit_types_on_external"
  add_index "business_unit_types", ["name"], name: "index_business_unit_types_on_name"
  add_index "business_unit_types", ["organization_id"], name: "index_business_unit_types_on_organization_id"

  create_table "business_units", force: true do |t|
    t.string   "name"
    t.integer  "business_unit_type_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "business_units", ["business_unit_type_id"], name: "index_business_units_on_business_unit_type_id"
  add_index "business_units", ["name"], name: "index_business_units_on_name"

  create_table "comments", force: true do |t|
    t.text     "comment"
    t.integer  "commentable_id"
    t.string   "commentable_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], name: "index_comments_on_commentable_id"
  add_index "comments", ["commentable_type"], name: "index_comments_on_commentable_type"
  add_index "comments", ["user_id"], name: "index_comments_on_user_id"

  create_table "conclusion_reviews", force: true do |t|
    t.string   "type"
    t.integer  "review_id"
    t.date     "issue_date"
    t.date     "close_date"
    t.text     "applied_procedures"
    t.text     "conclusion"
    t.boolean  "approved"
    t.integer  "lock_version",       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  add_index "conclusion_reviews", ["close_date"], name: "index_conclusion_reviews_on_close_date"
  add_index "conclusion_reviews", ["issue_date"], name: "index_conclusion_reviews_on_issue_date"
  add_index "conclusion_reviews", ["organization_id"], name: "index_conclusion_reviews_on_organization_id"
  add_index "conclusion_reviews", ["review_id"], name: "index_conclusion_reviews_on_review_id"
  add_index "conclusion_reviews", ["type"], name: "index_conclusion_reviews_on_type"

  create_table "control_objective_items", force: true do |t|
    t.text     "control_objective_text"
    t.integer  "order_number"
    t.integer  "relevance"
    t.integer  "design_score"
    t.integer  "compliance_score"
    t.integer  "sustantive_score"
    t.date     "audit_date"
    t.text     "auditor_comment"
    t.boolean  "finished"
    t.integer  "control_objective_id"
    t.integer  "review_id"
    t.integer  "lock_version",           default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "exclude_from_score",     default: false, null: false
    t.integer  "organization_id"
  end

  add_index "control_objective_items", ["control_objective_id"], name: "index_control_objective_items_on_control_objective_id"
  add_index "control_objective_items", ["organization_id"], name: "index_control_objective_items_on_organization_id"
  add_index "control_objective_items", ["review_id"], name: "index_control_objective_items_on_review_id"

  create_table "control_objectives", force: true do |t|
    t.text     "name"
    t.integer  "risk"
    t.integer  "relevance"
    t.integer  "order"
    t.integer  "process_control_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "obsolete",           default: false
    t.boolean  "continuous"
  end

  add_index "control_objectives", ["obsolete"], name: "index_control_objectives_on_obsolete"
  add_index "control_objectives", ["process_control_id"], name: "index_control_objectives_on_process_control_id"

  create_table "controls", force: true do |t|
    t.text     "control"
    t.text     "effects"
    t.text     "design_tests"
    t.text     "compliance_tests"
    t.text     "sustantive_tests"
    t.integer  "order"
    t.integer  "controllable_id"
    t.string   "controllable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "controls", ["controllable_type", "controllable_id"], name: "index_controls_on_controllable_type_and_controllable_id"

  create_table "costs", force: true do |t|
    t.text     "description"
    t.string   "cost_type"
    t.decimal  "cost",        precision: 15, scale: 2
    t.integer  "item_id"
    t.string   "item_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "costs", ["cost_type"], name: "index_costs_on_cost_type"
  add_index "costs", ["item_type", "item_id"], name: "index_costs_on_item_type_and_item_id"
  add_index "costs", ["user_id"], name: "index_costs_on_user_id"

  create_table "e_mails", force: true do |t|
    t.text     "to"
    t.text     "subject"
    t.text     "body"
    t.text     "attachments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  add_index "e_mails", ["created_at"], name: "index_e_mails_on_created_at"
  add_index "e_mails", ["organization_id"], name: "index_e_mails_on_organization_id"

  create_table "error_records", force: true do |t|
    t.text     "data"
    t.integer  "error"
    t.integer  "user_id"
    t.integer  "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "error_records", ["created_at"], name: "index_error_records_on_created_at"
  add_index "error_records", ["organization_id"], name: "index_error_records_on_organization_id"
  add_index "error_records", ["user_id"], name: "index_error_records_on_user_id"

  create_table "file_models", force: true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.integer  "lock_version",      default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "finding_answers", force: true do |t|
    t.text     "answer"
    t.text     "auditor_comments"
    t.date     "commitment_date"
    t.integer  "finding_id"
    t.integer  "user_id"
    t.integer  "file_model_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_answers", ["file_model_id"], name: "index_finding_answers_on_file_model_id"
  add_index "finding_answers", ["finding_id"], name: "index_finding_answers_on_finding_id"
  add_index "finding_answers", ["user_id"], name: "index_finding_answers_on_user_id"

  create_table "finding_relations", force: true do |t|
    t.string   "description",        null: false
    t.integer  "finding_id"
    t.integer  "related_finding_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_relations", ["finding_id"], name: "index_finding_relations_on_finding_id"
  add_index "finding_relations", ["related_finding_id"], name: "index_finding_relations_on_related_finding_id"

  create_table "finding_review_assignments", force: true do |t|
    t.integer  "finding_id"
    t.integer  "review_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_review_assignments", ["finding_id", "review_id"], name: "index_finding_review_assignments_on_finding_id_and_review_id"

  create_table "finding_user_assignments", force: true do |t|
    t.boolean  "process_owner",       default: false
    t.integer  "finding_id"
    t.string   "finding_type"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "responsible_auditor"
  end

  add_index "finding_user_assignments", ["finding_id", "finding_type", "user_id"], name: "fua_on_id_type_and_user_id"
  add_index "finding_user_assignments", ["finding_id", "finding_type"], name: "index_finding_user_assignments_on_finding_id_and_finding_type"

  create_table "findings", force: true do |t|
    t.string   "type"
    t.string   "review_code"
    t.text     "description"
    t.text     "answer"
    t.text     "audit_comments"
    t.date     "solution_date"
    t.date     "first_notification_date"
    t.date     "confirmation_date"
    t.date     "origination_date"
    t.boolean  "final"
    t.integer  "parent_id"
    t.integer  "state"
    t.integer  "notification_level",        default: 0
    t.integer  "lock_version",              default: 0
    t.integer  "control_objective_item_id"
    t.text     "audit_recommendations"
    t.text     "effect"
    t.integer  "risk"
    t.integer  "highest_risk"
    t.integer  "priority"
    t.date     "follow_up_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "repeated_of_id"
    t.date     "correction_date"
    t.date     "cause_analysis_date"
    t.integer  "organization_id"
    t.text     "correction"
    t.text     "cause_analysis"
    t.string   "title"
  end

  add_index "findings", ["control_objective_item_id"], name: "index_findings_on_control_objective_item_id"
  add_index "findings", ["created_at"], name: "index_findings_on_created_at"
  add_index "findings", ["final"], name: "index_findings_on_final"
  add_index "findings", ["first_notification_date"], name: "index_findings_on_first_notification_date"
  add_index "findings", ["follow_up_date"], name: "index_findings_on_follow_up_date"
  add_index "findings", ["organization_id"], name: "index_findings_on_organization_id"
  add_index "findings", ["parent_id"], name: "index_findings_on_parent_id"
  add_index "findings", ["repeated_of_id"], name: "index_findings_on_repeated_of_id"
  add_index "findings", ["state"], name: "index_findings_on_state"
  add_index "findings", ["title"], name: "index_findings_on_title"
  add_index "findings", ["type"], name: "index_findings_on_type"
  add_index "findings", ["updated_at"], name: "index_findings_on_updated_at"

  create_table "groups", force: true do |t|
    t.string   "name"
    t.string   "admin_email"
    t.string   "admin_hash"
    t.text     "description"
    t.integer  "lock_version", default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "groups", ["admin_email"], name: "index_groups_on_admin_email", unique: true
  add_index "groups", ["admin_hash"], name: "index_groups_on_admin_hash", unique: true
  add_index "groups", ["name"], name: "index_groups_on_name", unique: true

  create_table "image_models", force: true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size"
    t.datetime "image_updated_at"
    t.integer  "lock_version",       default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "ldap_configs", force: true do |t|
    t.string   "hostname",                          null: false
    t.integer  "port",                default: 389, null: false
    t.string   "basedn",                            null: false
    t.string   "login_mask",                        null: false
    t.string   "username_attribute",                null: false
    t.string   "name_attribute",                    null: false
    t.string   "last_name_attribute",               null: false
    t.string   "email_attribute",                   null: false
    t.string   "function_attribute"
    t.string   "roles_attribute",                   null: false
    t.string   "manager_attribute"
    t.integer  "organization_id",                   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "filter"
  end

  add_index "ldap_configs", ["organization_id"], name: "index_ldap_configs_on_organization_id"

  create_table "login_records", force: true do |t|
    t.integer  "user_id"
    t.text     "data"
    t.datetime "start"
    t.datetime "end"
    t.datetime "created_at"
    t.integer  "organization_id"
  end

  add_index "login_records", ["end"], name: "index_login_records_on_end"
  add_index "login_records", ["organization_id"], name: "index_login_records_on_organization_id"
  add_index "login_records", ["start"], name: "index_login_records_on_start"
  add_index "login_records", ["user_id"], name: "index_login_records_on_user_id"

  create_table "notification_relations", force: true do |t|
    t.integer  "notification_id"
    t.integer  "model_id"
    t.string   "model_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notification_relations", ["model_type", "model_id"], name: "index_notification_relations_on_model_type_and_model_id"
  add_index "notification_relations", ["notification_id"], name: "index_notification_relations_on_notification_id"

  create_table "notifications", force: true do |t|
    t.integer  "status"
    t.string   "confirmation_hash"
    t.text     "notes"
    t.datetime "confirmation_date"
    t.integer  "user_id"
    t.integer  "user_who_confirm_id"
    t.integer  "lock_version",        default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["confirmation_hash"], name: "index_notifications_on_confirmation_hash", unique: true
  add_index "notifications", ["status"], name: "index_notifications_on_status"
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id"
  add_index "notifications", ["user_who_confirm_id"], name: "index_notifications_on_user_who_confirm_id"

  create_table "old_passwords", force: true do |t|
    t.string   "password"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "old_passwords", ["created_at"], name: "index_old_passwords_on_created_at"
  add_index "old_passwords", ["user_id"], name: "index_old_passwords_on_user_id"

  create_table "organization_roles", force: true do |t|
    t.integer  "user_id"
    t.integer  "organization_id"
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "organization_roles", ["organization_id"], name: "index_organization_roles_on_organization_id"
  add_index "organization_roles", ["role_id"], name: "index_organization_roles_on_role_id"
  add_index "organization_roles", ["user_id"], name: "index_organization_roles_on_user_id"

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.string   "prefix"
    t.text     "description"
    t.integer  "group_id"
    t.integer  "image_model_id"
    t.integer  "lock_version",              default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",                    default: false
    t.boolean  "system_quality_management"
    t.text     "kind",                      default: "private"
  end

  add_index "organizations", ["group_id"], name: "index_organizations_on_group_id"
  add_index "organizations", ["image_model_id"], name: "index_organizations_on_image_model_id"
  add_index "organizations", ["name"], name: "index_organizations_on_name"
  add_index "organizations", ["prefix"], name: "index_organizations_on_prefix", unique: true

  create_table "periods", force: true do |t|
    t.integer  "number"
    t.text     "description"
    t.date     "start"
    t.date     "end"
    t.integer  "organization_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "periods", ["end"], name: "index_periods_on_end"
  add_index "periods", ["number"], name: "index_periods_on_number"
  add_index "periods", ["organization_id"], name: "index_periods_on_organization_id"
  add_index "periods", ["start"], name: "index_periods_on_start"

  create_table "plan_items", force: true do |t|
    t.string   "project"
    t.date     "start"
    t.date     "end"
    t.string   "predecessors"
    t.integer  "order_number"
    t.integer  "plan_id"
    t.integer  "business_unit_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plan_items", ["business_unit_id"], name: "index_plan_items_on_business_unit_id"
  add_index "plan_items", ["plan_id"], name: "index_plan_items_on_plan_id"

  create_table "plans", force: true do |t|
    t.integer  "period_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  add_index "plans", ["organization_id"], name: "index_plans_on_organization_id"
  add_index "plans", ["period_id"], name: "index_plans_on_period_id"

  create_table "polls", force: true do |t|
    t.text     "comments"
    t.boolean  "answered",         default: false
    t.integer  "lock_version",     default: 0
    t.integer  "user_id"
    t.integer  "questionnaire_id"
    t.integer  "pollable_id"
    t.string   "pollable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.string   "access_token"
    t.string   "customer_email"
  end

  add_index "polls", ["customer_email"], name: "index_polls_on_customer_email"
  add_index "polls", ["organization_id"], name: "index_polls_on_organization_id"
  add_index "polls", ["questionnaire_id"], name: "index_polls_on_questionnaire_id"

  create_table "privileges", force: true do |t|
    t.string   "module",     limit: 100
    t.boolean  "read",                   default: false
    t.boolean  "modify",                 default: false
    t.boolean  "erase",                  default: false
    t.boolean  "approval",               default: false
    t.integer  "role_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "privileges", ["role_id"], name: "index_privileges_on_role_id"

  create_table "process_controls", force: true do |t|
    t.string   "name"
    t.integer  "order"
    t.integer  "best_practice_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "obsolete",         default: false
  end

  add_index "process_controls", ["best_practice_id"], name: "index_process_controls_on_best_practice_id"
  add_index "process_controls", ["obsolete"], name: "index_process_controls_on_obsolete"

  create_table "questionnaires", force: true do |t|
    t.string   "name"
    t.integer  "lock_version",        default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
    t.string   "pollable_type"
    t.string   "email_subject"
    t.string   "email_link"
    t.string   "email_text"
    t.string   "email_clarification"
  end

  add_index "questionnaires", ["name"], name: "index_questionnaires_on_name"
  add_index "questionnaires", ["organization_id"], name: "index_questionnaires_on_organization_id"

  create_table "questions", force: true do |t|
    t.integer  "sort_order"
    t.integer  "answer_type"
    t.text     "question"
    t.integer  "questionnaire_id"
    t.integer  "lock_version",     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions", ["questionnaire_id"], name: "index_questions_on_questionnaire_id"

  create_table "related_user_relations", force: true do |t|
    t.integer  "user_id"
    t.integer  "related_user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "related_user_relations", ["user_id", "related_user_id"], name: "index_related_user_relations_on_user_id_and_related_user_id"

  create_table "resource_classes", force: true do |t|
    t.string   "name"
    t.integer  "unit"
    t.integer  "resource_class_type"
    t.integer  "organization_id"
    t.integer  "lock_version",        default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_classes", ["name"], name: "index_resource_classes_on_name"
  add_index "resource_classes", ["organization_id"], name: "index_resource_classes_on_organization_id"

  create_table "resource_utilizations", force: true do |t|
    t.decimal  "units",                  precision: 15, scale: 2
    t.decimal  "cost_per_unit",          precision: 15, scale: 2
    t.integer  "resource_consumer_id"
    t.string   "resource_consumer_type"
    t.integer  "resource_id"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_utilizations", ["resource_consumer_id", "resource_consumer_type"], name: "ru_consumer_consumer_type_idx"
  add_index "resource_utilizations", ["resource_id", "resource_type"], name: "ru_resource_resource_type_idx"

  create_table "resources", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "cost_per_unit",     precision: 15, scale: 2
    t.integer  "resource_class_id"
    t.integer  "lock_version",                               default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resources", ["resource_class_id"], name: "index_resources_on_resource_class_id"

  create_table "review_user_assignments", force: true do |t|
    t.integer  "assignment_type"
    t.integer  "review_id"
    t.integer  "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "review_user_assignments", ["review_id", "user_id"], name: "index_review_user_assignments_on_review_id_and_user_id"

  create_table "reviews", force: true do |t|
    t.string   "identification"
    t.text     "description"
    t.text     "survey"
    t.integer  "score"
    t.integer  "top_scale"
    t.integer  "achieved_scale"
    t.integer  "period_id"
    t.integer  "plan_item_id"
    t.integer  "file_model_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  add_index "reviews", ["file_model_id"], name: "index_reviews_on_file_model_id"
  add_index "reviews", ["identification"], name: "index_reviews_on_identification"
  add_index "reviews", ["organization_id"], name: "index_reviews_on_organization_id"
  add_index "reviews", ["period_id"], name: "index_reviews_on_period_id"
  add_index "reviews", ["plan_item_id"], name: "index_reviews_on_plan_item_id"

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "role_type"
    t.integer  "organization_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name"], name: "index_roles_on_name"
  add_index "roles", ["organization_id"], name: "index_roles_on_organization_id"

  create_table "settings", force: true do |t|
    t.string   "name",                        null: false
    t.string   "value",                       null: false
    t.text     "description"
    t.integer  "organization_id",             null: false
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["name", "organization_id"], name: "index_settings_on_name_and_organization_id", unique: true
  add_index "settings", ["name"], name: "index_settings_on_name"
  add_index "settings", ["organization_id"], name: "index_settings_on_organization_id"

  create_table "users", force: true do |t|
    t.string   "name",                 limit: 100
    t.string   "last_name",            limit: 100
    t.string   "language",             limit: 10
    t.string   "email",                limit: 100
    t.string   "user",                 limit: 30
    t.string   "function"
    t.string   "password",             limit: 128
    t.string   "salt"
    t.string   "change_password_hash"
    t.date     "password_changed"
    t.boolean  "enable",                           default: false
    t.boolean  "logged_in",                        default: false
    t.boolean  "group_admin",                      default: false
    t.integer  "resource_id"
    t.datetime "last_access"
    t.integer  "manager_id"
    t.integer  "failed_attempts",                  default: 0
    t.text     "notes"
    t.integer  "lock_version",                     default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "hash_changed"
    t.boolean  "hidden",                           default: false
  end

  add_index "users", ["change_password_hash"], name: "index_users_on_change_password_hash", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["group_admin"], name: "index_users_on_group_admin"
  add_index "users", ["hidden"], name: "index_users_on_hidden"
  add_index "users", ["manager_id"], name: "index_users_on_manager_id"
  add_index "users", ["resource_id"], name: "index_users_on_resource_id"
  add_index "users", ["user"], name: "index_users_on_user", unique: true

  create_table "versions", force: true do |t|
    t.integer  "item_id"
    t.string   "item_type"
    t.string   "event",           null: false
    t.integer  "whodunnit"
    t.text     "object"
    t.datetime "created_at"
    t.boolean  "important"
    t.integer  "organization_id"
  end

  add_index "versions", ["created_at"], name: "index_versions_on_created_at"
  add_index "versions", ["important"], name: "index_versions_on_important"
  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  add_index "versions", ["organization_id"], name: "index_versions_on_organization_id"
  add_index "versions", ["whodunnit"], name: "index_versions_on_whodunnit"

  create_table "work_papers", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "number_of_pages"
    t.text     "description"
    t.integer  "owner_id"
    t.string   "owner_type"
    t.integer  "file_model_id"
    t.integer  "organization_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_papers", ["file_model_id"], name: "index_work_papers_on_file_model_id"
  add_index "work_papers", ["organization_id"], name: "index_work_papers_on_organization_id"
  add_index "work_papers", ["owner_type", "owner_id"], name: "index_work_papers_on_owner_type_and_owner_id"

  create_table "workflow_items", force: true do |t|
    t.text     "task"
    t.date     "start"
    t.date     "end"
    t.string   "predecessors"
    t.integer  "order_number"
    t.integer  "workflow_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflow_items", ["workflow_id"], name: "index_workflow_items_on_workflow_id"

  create_table "workflows", force: true do |t|
    t.integer  "review_id"
    t.integer  "period_id"
    t.integer  "lock_version",    default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id"
  end

  add_index "workflows", ["organization_id"], name: "index_workflows_on_organization_id"
  add_index "workflows", ["period_id"], name: "index_workflows_on_period_id"
  add_index "workflows", ["review_id"], name: "index_workflows_on_review_id"

  Foreigner.load
end
