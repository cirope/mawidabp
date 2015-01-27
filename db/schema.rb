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

ActiveRecord::Schema.define(version: 20150123035232) do

  create_table "answer_options", force: true do |t|
    t.text     "option"
    t.integer  "question_id",  precision: 38, scale: 0
    t.integer  "lock_version", precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "answer_options", ["question_id"], name: "i_answer_options_question_id"

  create_table "answers", force: true do |t|
    t.text     "comments"
    t.string   "type"
    t.integer  "question_id",      precision: 38, scale: 0
    t.integer  "poll_id",          precision: 38, scale: 0
    t.integer  "lock_version",     precision: 38, scale: 0, default: 0
    t.text     "answer"
    t.integer  "answer_option_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "answers", ["poll_id"], name: "index_answers_on_poll_id"
  add_index "answers", ["question_id"], name: "index_answers_on_question_id"
  add_index "answers", ["type", "id"], name: "index_answers_on_type_and_id"

  create_table "best_practices", force: true do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "organization_id", precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "obsolete",        precision: 1,  scale: 0, default: false
  end

  add_index "best_practices", ["created_at"], name: "i_best_practices_created_at"
  add_index "best_practices", ["obsolete"], name: "i_best_practices_obsolete"
  add_index "best_practices", ["organization_id"], name: "i_bes_pra_org_id"

  create_table "business_unit_types", force: true do |t|
    t.string   "name"
    t.boolean  "external",            precision: 1,  scale: 0, default: false, null: false
    t.string   "business_unit_label"
    t.string   "project_label"
    t.integer  "organization_id",     precision: 38, scale: 0
    t.integer  "lock_version",        precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "business_unit_types", ["external"], name: "i_business_unit_types_external"
  add_index "business_unit_types", ["name"], name: "i_business_unit_types_name"
  add_index "business_unit_types", ["organization_id"], name: "i_bus_uni_typ_org_id"

  create_table "business_units", force: true do |t|
    t.string   "name"
    t.integer  "business_unit_type_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "business_units", ["business_unit_type_id"], name: "i_bus_uni_bus_uni_typ_id"
  add_index "business_units", ["name"], name: "index_business_units_on_name"

  create_table "comments", force: true do |t|
    t.text     "comment"
    t.integer  "commentable_id",   precision: 38, scale: 0
    t.string   "commentable_type"
    t.integer  "user_id",          precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "comments", ["commentable_id"], name: "i_comments_commentable_id"
  add_index "comments", ["commentable_type"], name: "i_comments_commentable_type"
  add_index "comments", ["user_id"], name: "index_comments_on_user_id"

  create_table "conclusion_reviews", force: true do |t|
    t.string   "type"
    t.integer  "review_id",          precision: 38, scale: 0
    t.datetime "issue_date"
    t.datetime "close_date"
    t.text     "applied_procedures"
    t.text     "conclusion"
    t.boolean  "approved",           precision: 1,  scale: 0
    t.integer  "lock_version",       precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id",    precision: 38, scale: 0
  end

  add_index "conclusion_reviews", ["close_date"], name: "i_con_rev_clo_dat"
  add_index "conclusion_reviews", ["issue_date"], name: "i_con_rev_iss_dat"
  add_index "conclusion_reviews", ["organization_id"], name: "i_con_rev_org_id"
  add_index "conclusion_reviews", ["review_id"], name: "i_conclusion_reviews_review_id"
  add_index "conclusion_reviews", ["type"], name: "i_conclusion_reviews_type"

  create_table "control_objective_items", force: true do |t|
    t.text     "control_objective_text"
    t.integer  "order_number",           precision: 38, scale: 0
    t.integer  "relevance",              precision: 38, scale: 0
    t.integer  "design_score",           precision: 38, scale: 0
    t.integer  "compliance_score",       precision: 38, scale: 0
    t.integer  "sustantive_score",       precision: 38, scale: 0
    t.datetime "audit_date"
    t.text     "auditor_comment"
    t.boolean  "finished",               precision: 1,  scale: 0
    t.integer  "control_objective_id",   precision: 38, scale: 0
    t.integer  "review_id",              precision: 38, scale: 0
    t.integer  "lock_version",           precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "exclude_from_score",     precision: 1,  scale: 0, default: false, null: false
    t.integer  "organization_id",        precision: 38, scale: 0
  end

  add_index "control_objective_items", ["control_objective_id"], name: "i_con_obj_ite_con_obj_id"
  add_index "control_objective_items", ["organization_id"], name: "i_con_obj_ite_org_id"
  add_index "control_objective_items", ["review_id"], name: "i_con_obj_ite_rev_id"

  create_table "control_objectives", force: true do |t|
    t.text     "name"
    t.integer  "risk",               precision: 38, scale: 0
    t.integer  "relevance",          precision: 38, scale: 0
    t.integer  "order",              precision: 38, scale: 0
    t.integer  "process_control_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "obsolete",           precision: 1,  scale: 0, default: false
  end

  add_index "control_objectives", ["obsolete"], name: "i_control_objectives_obsolete"
  add_index "control_objectives", ["process_control_id"], name: "i_con_obj_pro_con_id"

  create_table "controls", force: true do |t|
    t.text     "control"
    t.text     "effects"
    t.text     "design_tests"
    t.text     "compliance_tests"
    t.text     "sustantive_tests"
    t.integer  "order",             precision: 38, scale: 0
    t.integer  "controllable_id",   precision: 38, scale: 0
    t.string   "controllable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "controls", ["controllable_type", "controllable_id"], name: "i_con_con_typ_con_id"

  create_table "costs", force: true do |t|
    t.text     "description"
    t.string   "cost_type"
    t.decimal  "cost",        precision: 15, scale: 2
    t.integer  "item_id",     precision: 38, scale: 0
    t.string   "item_type"
    t.integer  "user_id",     precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "costs", ["cost_type"], name: "index_costs_on_cost_type"
  add_index "costs", ["item_type", "item_id"], name: "i_costs_item_type_item_id"
  add_index "costs", ["user_id"], name: "index_costs_on_user_id"

  create_table "def$_aqcall", id: false, force: true do |t|
    t.string    "q_name",            limit: 30
    t.raw       "msgid",             limit: 16
    t.string    "corrid",            limit: 128
    t.decimal   "priority"
    t.decimal   "state"
    t.timestamp "delay",             limit: 6
    t.decimal   "expiration"
    t.timestamp "time_manager_info", limit: 6
    t.decimal   "local_order_no"
    t.decimal   "chain_no"
    t.decimal   "cscn"
    t.decimal   "dscn"
    t.timestamp "enq_time",          limit: 6
    t.decimal   "enq_uid"
    t.string    "enq_tid",           limit: 30,  null: false
    t.timestamp "deq_time",          limit: 6
    t.decimal   "deq_uid"
    t.string    "deq_tid",           limit: 30
    t.decimal   "retry_count"
    t.string    "exception_qschema", limit: 30
    t.string    "exception_queue",   limit: 30
    t.decimal   "step_no",                       null: false
    t.decimal   "recipient_key"
    t.raw       "dequeue_msgid",     limit: 16
    t.binary    "user_data"
  end

  add_index "def$_aqcall", ["cscn", "enq_tid"], name: "def$_tranorder"

  create_table "def$_aqerror", id: false, force: true do |t|
    t.string    "q_name",            limit: 30
    t.raw       "msgid",             limit: 16
    t.string    "corrid",            limit: 128
    t.decimal   "priority"
    t.decimal   "state"
    t.timestamp "delay",             limit: 6
    t.decimal   "expiration"
    t.timestamp "time_manager_info", limit: 6
    t.decimal   "local_order_no"
    t.decimal   "chain_no"
    t.decimal   "cscn"
    t.decimal   "dscn"
    t.timestamp "enq_time",          limit: 6
    t.decimal   "enq_uid"
    t.string    "enq_tid",           limit: 30,  null: false
    t.timestamp "deq_time",          limit: 6
    t.decimal   "deq_uid"
    t.string    "deq_tid",           limit: 30
    t.decimal   "retry_count"
    t.string    "exception_qschema", limit: 30
    t.string    "exception_queue",   limit: 30
    t.decimal   "step_no",                       null: false
    t.decimal   "recipient_key"
    t.raw       "dequeue_msgid",     limit: 16
    t.binary    "user_data"
  end

  create_table "e_mails", force: true do |t|
    t.text     "to"
    t.text     "subject"
    t.text     "body"
    t.text     "attachments"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id", precision: 38, scale: 0
  end

  add_index "e_mails", ["created_at"], name: "index_e_mails_on_created_at"
  add_index "e_mails", ["organization_id"], name: "i_e_mails_organization_id"

  create_table "error_records", force: true do |t|
    t.text     "data"
    t.integer  "error",           precision: 38, scale: 0
    t.integer  "user_id",         precision: 38, scale: 0
    t.integer  "organization_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "error_records", ["created_at"], name: "i_error_records_created_at"
  add_index "error_records", ["organization_id"], name: "i_err_rec_org_id"
  add_index "error_records", ["user_id"], name: "index_error_records_on_user_id"

  create_table "file_models", force: true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size",    precision: 38, scale: 0
    t.datetime "file_updated_at"
    t.integer  "lock_version",      precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "finding_answers", force: true do |t|
    t.text     "answer"
    t.text     "auditor_comments"
    t.datetime "commitment_date"
    t.integer  "finding_id",       precision: 38, scale: 0
    t.integer  "user_id",          precision: 38, scale: 0
    t.integer  "file_model_id",    precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_answers", ["file_model_id"], name: "i_fin_ans_fil_mod_id"
  add_index "finding_answers", ["finding_id"], name: "i_finding_answers_finding_id"
  add_index "finding_answers", ["user_id"], name: "i_finding_answers_user_id"

  create_table "finding_relations", force: true do |t|
    t.string   "description",                                 null: false
    t.integer  "finding_id",         precision: 38, scale: 0
    t.integer  "related_finding_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_relations", ["finding_id"], name: "i_finding_relations_finding_id"
  add_index "finding_relations", ["related_finding_id"], name: "i_fin_rel_rel_fin_id"

  create_table "finding_review_assignments", force: true do |t|
    t.integer  "finding_id", precision: 38, scale: 0
    t.integer  "review_id",  precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "finding_review_assignments", ["finding_id", "review_id"], name: "i_fin_rev_ass_fin_id_rev_id"

  create_table "finding_user_assignments", force: true do |t|
    t.boolean  "process_owner",       precision: 1,  scale: 0, default: false
    t.integer  "finding_id",          precision: 38, scale: 0
    t.string   "finding_type"
    t.integer  "user_id",             precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "responsible_auditor", precision: 1,  scale: 0
  end

  add_index "finding_user_assignments", ["finding_id", "finding_type", "user_id"], name: "fua_on_id_type_and_user_id"
  add_index "finding_user_assignments", ["finding_id", "finding_type"], name: "i_fin_use_ass_fin_id_fin_typ"

  create_table "findings", force: true do |t|
    t.string   "type"
    t.string   "review_code"
    t.text     "description"
    t.text     "answer"
    t.text     "audit_comments"
    t.datetime "solution_date"
    t.datetime "first_notification_date"
    t.datetime "confirmation_date"
    t.datetime "origination_date"
    t.boolean  "final",                     precision: 1,  scale: 0
    t.integer  "parent_id",                 precision: 38, scale: 0
    t.integer  "state",                     precision: 38, scale: 0
    t.integer  "notification_level",        precision: 38, scale: 0, default: 0
    t.integer  "lock_version",              precision: 38, scale: 0, default: 0
    t.integer  "control_objective_item_id", precision: 38, scale: 0
    t.text     "audit_recommendations"
    t.text     "effect"
    t.integer  "risk",                      precision: 38, scale: 0
    t.integer  "highest_risk",              precision: 38, scale: 0
    t.integer  "priority",                  precision: 38, scale: 0
    t.datetime "follow_up_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "repeated_of_id",            precision: 38, scale: 0
    t.datetime "correction_date"
    t.datetime "cause_analysis_date"
    t.integer  "organization_id",           precision: 38, scale: 0
    t.text     "correction"
    t.text     "cause_analysis"
    t.string   "title"
  end

  add_index "findings", ["control_objective_item_id"], name: "i_fin_con_obj_ite_id"
  add_index "findings", ["created_at"], name: "index_findings_on_created_at"
  add_index "findings", ["final"], name: "index_findings_on_final"
  add_index "findings", ["first_notification_date"], name: "i_fin_fir_not_dat"
  add_index "findings", ["follow_up_date"], name: "i_findings_follow_up_date"
  add_index "findings", ["organization_id"], name: "i_findings_organization_id"
  add_index "findings", ["parent_id"], name: "index_findings_on_parent_id"
  add_index "findings", ["repeated_of_id"], name: "i_findings_repeated_of_id"
  add_index "findings", ["state"], name: "index_findings_on_state"
  add_index "findings", ["type"], name: "index_findings_on_type"
  add_index "findings", ["updated_at"], name: "index_findings_on_updated_at"

  create_table "groups", force: true do |t|
    t.string   "name"
    t.string   "admin_email"
    t.string   "admin_hash"
    t.text     "description"
    t.integer  "lock_version", precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "groups", ["admin_email"], name: "index_groups_on_admin_email", unique: true
  add_index "groups", ["admin_hash"], name: "index_groups_on_admin_hash", unique: true
  add_index "groups", ["name"], name: "index_groups_on_name", unique: true

  create_table "image_models", force: true do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size",    precision: 38, scale: 0
    t.datetime "image_updated_at"
    t.integer  "lock_version",       precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "login_records", force: true do |t|
    t.integer  "user_id",         precision: 38, scale: 0
    t.text     "data"
    t.datetime "start"
    t.datetime "end"
    t.datetime "created_at"
    t.integer  "organization_id", precision: 38, scale: 0
  end

  add_index "login_records", ["end"], name: "index_login_records_on_end"
  add_index "login_records", ["organization_id"], name: "i_log_rec_org_id"
  add_index "login_records", ["start"], name: "index_login_records_on_start"
  add_index "login_records", ["user_id"], name: "index_login_records_on_user_id"

  create_table "notification_relations", force: true do |t|
    t.integer  "notification_id", precision: 38, scale: 0
    t.integer  "model_id",        precision: 38, scale: 0
    t.string   "model_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notification_relations", ["model_type", "model_id"], name: "i_not_rel_mod_typ_mod_id"
  add_index "notification_relations", ["notification_id"], name: "i_not_rel_not_id"

  create_table "notifications", force: true do |t|
    t.integer  "status",              precision: 38, scale: 0
    t.string   "confirmation_hash"
    t.text     "notes"
    t.datetime "confirmation_date"
    t.integer  "user_id",             precision: 38, scale: 0
    t.integer  "user_who_confirm_id", precision: 38, scale: 0
    t.integer  "lock_version",        precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "notifications", ["confirmation_hash"], name: "i_not_con_has", unique: true
  add_index "notifications", ["status"], name: "index_notifications_on_status"
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id"
  add_index "notifications", ["user_who_confirm_id"], name: "i_not_use_who_con_id"

  create_table "old_passwords", force: true do |t|
    t.string   "password"
    t.integer  "user_id",    precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "old_passwords", ["created_at"], name: "i_old_passwords_created_at"
  add_index "old_passwords", ["user_id"], name: "index_old_passwords_on_user_id"

  create_table "organization_roles", force: true do |t|
    t.integer  "user_id",         precision: 38, scale: 0
    t.integer  "organization_id", precision: 38, scale: 0
    t.integer  "role_id",         precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "organization_roles", ["organization_id"], name: "i_org_rol_org_id"
  add_index "organization_roles", ["role_id"], name: "i_organization_roles_role_id"
  add_index "organization_roles", ["user_id"], name: "i_organization_roles_user_id"

  create_table "organizations", force: true do |t|
    t.string   "name"
    t.string   "prefix"
    t.text     "description"
    t.integer  "group_id",                  precision: 38, scale: 0
    t.integer  "image_model_id",            precision: 38, scale: 0
    t.integer  "lock_version",              precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "public",                    precision: 1,  scale: 0, default: false
    t.boolean  "system_quality_management", precision: 1,  scale: 0
    t.text     "kind",                                               default: "private"
  end

  add_index "organizations", ["group_id"], name: "i_organizations_group_id"
  add_index "organizations", ["image_model_id"], name: "i_organizations_image_model_id"
  add_index "organizations", ["name"], name: "index_organizations_on_name"
  add_index "organizations", ["prefix"], name: "index_organizations_on_prefix", unique: true

  create_table "periods", force: true do |t|
    t.integer  "number",          precision: 38, scale: 0
    t.text     "description"
    t.datetime "start"
    t.datetime "end"
    t.integer  "organization_id", precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "periods", ["end"], name: "index_periods_on_end"
  add_index "periods", ["number"], name: "index_periods_on_number"
  add_index "periods", ["organization_id"], name: "i_periods_organization_id"
  add_index "periods", ["start"], name: "index_periods_on_start"

  create_table "plan_items", force: true do |t|
    t.string   "project"
    t.datetime "start"
    t.datetime "end"
    t.string   "predecessors"
    t.integer  "order_number",     precision: 38, scale: 0
    t.integer  "plan_id",          precision: 38, scale: 0
    t.integer  "business_unit_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "plan_items", ["business_unit_id"], name: "i_plan_items_business_unit_id"
  add_index "plan_items", ["plan_id"], name: "index_plan_items_on_plan_id"

  create_table "plans", force: true do |t|
    t.integer  "period_id",       precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id", precision: 38, scale: 0
  end

  add_index "plans", ["organization_id"], name: "index_plans_on_organization_id"
  add_index "plans", ["period_id"], name: "index_plans_on_period_id"

  create_table "polls", force: true do |t|
    t.text     "comments"
    t.boolean  "answered",         precision: 1,  scale: 0, default: false
    t.integer  "lock_version",     precision: 38, scale: 0, default: 0
    t.integer  "user_id",          precision: 38, scale: 0
    t.integer  "questionnaire_id", precision: 38, scale: 0
    t.integer  "pollable_id",      precision: 38, scale: 0
    t.string   "pollable_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id",  precision: 38, scale: 0
    t.string   "access_token"
    t.string   "customer_email"
  end

  add_index "polls", ["customer_email"], name: "index_polls_on_customer_email"
  add_index "polls", ["organization_id"], name: "index_polls_on_organization_id"
  add_index "polls", ["questionnaire_id"], name: "i_polls_questionnaire_id"

  create_table "privileges", force: true do |t|
    t.string   "module",     limit: 100
    t.boolean  "read",                   precision: 1,  scale: 0, default: false
    t.boolean  "modify",                 precision: 1,  scale: 0, default: false
    t.boolean  "erase",                  precision: 1,  scale: 0, default: false
    t.boolean  "approval",               precision: 1,  scale: 0, default: false
    t.integer  "role_id",                precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "privileges", ["role_id"], name: "index_privileges_on_role_id"

  create_table "process_controls", force: true do |t|
    t.string   "name"
    t.integer  "order",            precision: 38, scale: 0
    t.integer  "best_practice_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "obsolete",         precision: 1,  scale: 0, default: false
  end

  add_index "process_controls", ["best_practice_id"], name: "i_pro_con_bes_pra_id"
  add_index "process_controls", ["obsolete"], name: "i_process_controls_obsolete"

  create_table "questionnaires", force: true do |t|
    t.string   "name"
    t.integer  "lock_version",        precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id",     precision: 38, scale: 0
    t.string   "pollable_type"
    t.string   "email_subject"
    t.string   "email_link"
    t.string   "email_text"
    t.string   "email_clarification"
  end

  add_index "questionnaires", ["name"], name: "index_questionnaires_on_name"
  add_index "questionnaires", ["organization_id"], name: "i_que_org_id"

  create_table "questions", force: true do |t|
    t.integer  "sort_order",       precision: 38, scale: 0
    t.integer  "answer_type",      precision: 38, scale: 0
    t.text     "question"
    t.integer  "questionnaire_id", precision: 38, scale: 0
    t.integer  "lock_version",     precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "questions", ["questionnaire_id"], name: "i_questions_questionnaire_id"

  create_table "related_user_relations", force: true do |t|
    t.integer  "user_id",         precision: 38, scale: 0
    t.integer  "related_user_id", precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "related_user_relations", ["user_id", "related_user_id"], name: "ibff96752fbe4d0f3af118e7ce3391"

  create_table "resource_classes", force: true do |t|
    t.string   "name"
    t.integer  "unit",                precision: 38, scale: 0
    t.integer  "resource_class_type", precision: 38, scale: 0
    t.integer  "organization_id",     precision: 38, scale: 0
    t.integer  "lock_version",        precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resource_classes", ["name"], name: "index_resource_classes_on_name"
  add_index "resource_classes", ["organization_id"], name: "i_res_cla_org_id"

  create_table "resource_utilizations", force: true do |t|
    t.decimal  "units",                  precision: 15, scale: 2
    t.decimal  "cost_per_unit",          precision: 15, scale: 2
    t.integer  "resource_consumer_id",   precision: 38, scale: 0
    t.string   "resource_consumer_type"
    t.integer  "resource_id",            precision: 38, scale: 0
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
    t.integer  "resource_class_id", precision: 38, scale: 0
    t.integer  "lock_version",      precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "resources", ["resource_class_id"], name: "i_resources_resource_class_id"

  create_table "review_user_assignments", force: true do |t|
    t.integer  "assignment_type", precision: 38, scale: 0
    t.integer  "review_id",       precision: 38, scale: 0
    t.integer  "user_id",         precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "review_user_assignments", ["review_id", "user_id"], name: "i_rev_use_ass_rev_id_use_id"

  create_table "reviews", force: true do |t|
    t.string   "identification"
    t.text     "description"
    t.text     "survey"
    t.integer  "score",           precision: 38, scale: 0
    t.integer  "top_scale",       precision: 38, scale: 0
    t.integer  "achieved_scale",  precision: 38, scale: 0
    t.integer  "period_id",       precision: 38, scale: 0
    t.integer  "plan_item_id",    precision: 38, scale: 0
    t.integer  "file_model_id",   precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id", precision: 38, scale: 0
  end

  add_index "reviews", ["file_model_id"], name: "index_reviews_on_file_model_id"
  add_index "reviews", ["identification"], name: "i_reviews_identification"
  add_index "reviews", ["organization_id"], name: "i_reviews_organization_id"
  add_index "reviews", ["period_id"], name: "index_reviews_on_period_id"
  add_index "reviews", ["plan_item_id"], name: "index_reviews_on_plan_item_id"

  create_table "roles", force: true do |t|
    t.string   "name"
    t.integer  "role_type",       precision: 38, scale: 0
    t.integer  "organization_id", precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "roles", ["name"], name: "index_roles_on_name"
  add_index "roles", ["organization_id"], name: "index_roles_on_organization_id"

  create_table "settings", force: true do |t|
    t.string   "name",                                                 null: false
    t.string   "value",                                                null: false
    t.text     "description"
    t.integer  "organization_id", precision: 38, scale: 0,             null: false
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "settings", ["name", "organization_id"], name: "i_set_nam_org_id", unique: true
  add_index "settings", ["name"], name: "index_settings_on_name"
  add_index "settings", ["organization_id"], name: "i_settings_organization_id"

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
    t.datetime "password_changed"
    t.boolean  "enable",                           precision: 1,  scale: 0, default: false
    t.boolean  "logged_in",                        precision: 1,  scale: 0, default: false
    t.boolean  "group_admin",                      precision: 1,  scale: 0, default: false
    t.integer  "resource_id",                      precision: 38, scale: 0
    t.datetime "last_access"
    t.integer  "manager_id",                       precision: 38, scale: 0
    t.integer  "failed_attempts",                  precision: 38, scale: 0, default: 0
    t.text     "notes"
    t.integer  "lock_version",                     precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "hash_changed"
    t.boolean  "hidden",                           precision: 1,  scale: 0, default: false
  end

  add_index "users", ["change_password_hash"], name: "i_users_change_password_hash", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["group_admin"], name: "index_users_on_group_admin"
  add_index "users", ["hidden"], name: "index_users_on_hidden"
  add_index "users", ["manager_id"], name: "index_users_on_manager_id"
  add_index "users", ["resource_id"], name: "index_users_on_resource_id"
  add_index "users", ["user"], name: "index_users_on_user", unique: true

  create_table "versions", force: true do |t|
    t.integer  "item_id",         precision: 38, scale: 0
    t.string   "item_type"
    t.string   "event",                                    null: false
    t.integer  "whodunnit",       precision: 38, scale: 0
    t.text     "object"
    t.datetime "created_at"
    t.boolean  "important",       precision: 1,  scale: 0
    t.integer  "organization_id", precision: 38, scale: 0
  end

  add_index "versions", ["created_at"], name: "index_versions_on_created_at"
  add_index "versions", ["important"], name: "index_versions_on_important"
  add_index "versions", ["item_type", "item_id"], name: "i_versions_item_type_item_id"
  add_index "versions", ["organization_id"], name: "i_versions_organization_id"
  add_index "versions", ["whodunnit"], name: "index_versions_on_whodunnit"

  create_table "work_papers", force: true do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "number_of_pages", precision: 38, scale: 0
    t.text     "description"
    t.integer  "owner_id",        precision: 38, scale: 0
    t.string   "owner_type"
    t.integer  "file_model_id",   precision: 38, scale: 0
    t.integer  "organization_id", precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "work_papers", ["file_model_id"], name: "i_work_papers_file_model_id"
  add_index "work_papers", ["organization_id"], name: "i_work_papers_organization_id"
  add_index "work_papers", ["owner_type", "owner_id"], name: "i_wor_pap_own_typ_own_id"

  create_table "workflow_items", force: true do |t|
    t.text     "task"
    t.datetime "start"
    t.datetime "end"
    t.string   "predecessors"
    t.integer  "order_number", precision: 38, scale: 0
    t.integer  "workflow_id",  precision: 38, scale: 0
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "workflow_items", ["workflow_id"], name: "i_workflow_items_workflow_id"

  create_table "workflows", force: true do |t|
    t.integer  "review_id",       precision: 38, scale: 0
    t.integer  "period_id",       precision: 38, scale: 0
    t.integer  "lock_version",    precision: 38, scale: 0, default: 0
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "organization_id", precision: 38, scale: 0
  end

  add_index "workflows", ["organization_id"], name: "i_workflows_organization_id"
  add_index "workflows", ["period_id"], name: "index_workflows_on_period_id"
  add_index "workflows", ["review_id"], name: "index_workflows_on_review_id"

  add_foreign_key "best_practices", "organizations", name: "bes_pra_org_id_fk"

  add_foreign_key "business_unit_types", "organizations", name: "bus_uni_typ_org_id_fk"

  add_foreign_key "business_units", "business_unit_types", name: "bus_uni_bus_uni_typ_id_fk"

  add_foreign_key "comments", "users", name: "comments_user_id_fk"

  add_foreign_key "conclusion_reviews", "reviews", name: "con_rev_rev_id_fk"

  add_foreign_key "control_objective_items", "control_objectives", name: "con_obj_ite_con_obj_id_fk"
  add_foreign_key "control_objective_items", "reviews", name: "con_obj_ite_rev_id_fk"

  add_foreign_key "control_objectives", "process_controls", name: "con_obj_pro_con_id_fk"

  add_foreign_key "costs", "users", name: "costs_user_id_fk"

  add_foreign_key "error_records", "organizations", name: "err_rec_org_id_fk"
  add_foreign_key "error_records", "users", name: "error_records_user_id_fk"

  add_foreign_key "finding_answers", "file_models", name: "fin_ans_fil_mod_id_fk"
  add_foreign_key "finding_answers", "findings", name: "finding_answers_finding_id_fk"
  add_foreign_key "finding_answers", "users", name: "finding_answers_user_id_fk"

  add_foreign_key "finding_relations", "findings", column: "related_finding_id", name: "fin_rel_rel_fin_id_fk"
  add_foreign_key "finding_relations", "findings", name: "fin_rel_fin_id_fk"

  add_foreign_key "finding_review_assignments", "findings", name: "fin_rev_ass_fin_id_fk"
  add_foreign_key "finding_review_assignments", "reviews", name: "fin_rev_ass_rev_id_fk"

  add_foreign_key "finding_user_assignments", "findings", name: "fin_use_ass_fin_id_fk"
  add_foreign_key "finding_user_assignments", "users", name: "fin_use_ass_use_id_fk"

  add_foreign_key "findings", "control_objective_items", name: "fin_con_obj_ite_id_fk"
  add_foreign_key "findings", "findings", column: "repeated_of_id", name: "findings_repeated_of_id_fk"

  add_foreign_key "login_records", "organizations", name: "log_rec_org_id_fk"
  add_foreign_key "login_records", "users", name: "login_records_user_id_fk"

  add_foreign_key "notification_relations", "notifications", name: "not_rel_not_id_fk"

  add_foreign_key "notifications", "users", column: "user_who_confirm_id", name: "not_use_who_con_id_fk"
  add_foreign_key "notifications", "users", name: "notifications_user_id_fk"

  add_foreign_key "old_passwords", "users", name: "old_passwords_user_id_fk"

  add_foreign_key "organization_roles", "organizations", name: "org_rol_org_id_fk"
  add_foreign_key "organization_roles", "roles", name: "organization_roles_role_id_fk"
  add_foreign_key "organization_roles", "users", name: "organization_roles_user_id_fk"

  add_foreign_key "organizations", "groups", name: "organizations_group_id_fk"
  add_foreign_key "organizations", "image_models", name: "org_ima_mod_id_fk"

  add_foreign_key "periods", "organizations", name: "periods_organization_id_fk"

  add_foreign_key "plan_items", "business_units", name: "plan_items_business_unit_id_fk"
  add_foreign_key "plan_items", "plans", name: "plan_items_plan_id_fk"

  add_foreign_key "plans", "periods", name: "plans_period_id_fk"

  add_foreign_key "privileges", "roles", name: "privileges_role_id_fk"

  add_foreign_key "process_controls", "best_practices", name: "pro_con_bes_pra_id_fk"

  add_foreign_key "resource_classes", "organizations", name: "res_cla_org_id_fk"

  add_foreign_key "resources", "resource_classes", name: "resources_resource_class_id_fk"

  add_foreign_key "review_user_assignments", "reviews", name: "rev_use_ass_rev_id_fk"
  add_foreign_key "review_user_assignments", "users", name: "rev_use_ass_use_id_fk"

  add_foreign_key "reviews", "file_models", name: "reviews_file_model_id_fk"
  add_foreign_key "reviews", "periods", name: "reviews_period_id_fk"
  add_foreign_key "reviews", "plan_items", name: "reviews_plan_item_id_fk"

  add_foreign_key "roles", "organizations", name: "roles_organization_id_fk"

  add_foreign_key "settings", "organizations", name: "settings_organization_id_fk"

  add_foreign_key "users", "resources", name: "users_resource_id_fk"
  add_foreign_key "users", "users", column: "manager_id", name: "users_manager_id_fk"

  add_foreign_key "work_papers", "file_models", name: "work_papers_file_model_id_fk"
  add_foreign_key "work_papers", "organizations", name: "work_papers_organization_id_fk"

  add_foreign_key "workflow_items", "workflows", name: "workflow_items_workflow_id_fk"

  add_foreign_key "workflows", "periods", name: "workflows_period_id_fk"
  add_foreign_key "workflows", "reviews", name: "workflows_review_id_fk"

  add_synonym "syscatalog", "sys.syscatalog", force: true
  add_synonym "catalog", "sys.catalog", force: true
  add_synonym "tab", "sys.tab", force: true
  add_synonym "col", "sys.col", force: true
  add_synonym "tabquotas", "sys.tabquotas", force: true
  add_synonym "sysfiles", "sys.sysfiles", force: true
  add_synonym "publicsyn", "sys.publicsyn", force: true
  add_synonym "product_user_profile", "system.sqlplus_product_profile", force: true

end
