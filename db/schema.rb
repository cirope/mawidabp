# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_07_14_191248) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "btree_gin"
  enable_extension "pg_trgm"
  enable_extension "plpgsql"

  create_table "achievements", id: :serial, force: :cascade do |t|
    t.integer "benefit_id", null: false
    t.decimal "amount", precision: 15, scale: 2
    t.text "comment"
    t.integer "finding_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["benefit_id"], name: "index_achievements_on_benefit_id"
    t.index ["finding_id"], name: "index_achievements_on_finding_id"
  end

  create_table "answer_options", id: :serial, force: :cascade do |t|
    t.text "option"
    t.integer "question_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["question_id"], name: "index_answer_options_on_question_id"
  end

  create_table "answers", id: :serial, force: :cascade do |t|
    t.text "comments"
    t.string "type"
    t.integer "question_id"
    t.integer "poll_id"
    t.integer "lock_version", default: 0
    t.text "answer"
    t.integer "answer_option_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["poll_id"], name: "index_answers_on_poll_id"
    t.index ["question_id"], name: "index_answers_on_question_id"
    t.index ["type", "id"], name: "index_answers_on_type_and_id"
  end

  create_table "benefits", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "kind", null: false
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_benefits_on_organization_id"
  end

  create_table "best_practice_comments", force: :cascade do |t|
    t.text "auditor_comment"
    t.bigint "review_id", null: false
    t.bigint "best_practice_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["best_practice_id"], name: "index_best_practice_comments_on_best_practice_id"
    t.index ["review_id"], name: "index_best_practice_comments_on_review_id"
  end

  create_table "best_practice_projects", force: :cascade do |t|
    t.bigint "best_practice_id", null: false
    t.bigint "plan_item_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["best_practice_id"], name: "index_best_practice_projects_on_best_practice_id"
    t.index ["plan_item_id"], name: "index_best_practice_projects_on_plan_item_id"
  end

  create_table "best_practices", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "obsolete", default: false
    t.boolean "shared", default: false
    t.integer "group_id"
    t.index ["created_at"], name: "index_best_practices_on_created_at"
    t.index ["group_id"], name: "index_best_practices_on_group_id"
    t.index ["obsolete"], name: "index_best_practices_on_obsolete"
    t.index ["organization_id"], name: "index_best_practices_on_organization_id"
    t.index ["shared"], name: "index_best_practices_on_shared"
  end

  create_table "business_unit_findings", id: :serial, force: :cascade do |t|
    t.integer "business_unit_id"
    t.integer "finding_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_unit_id"], name: "index_business_unit_findings_on_business_unit_id"
    t.index ["finding_id"], name: "index_business_unit_findings_on_finding_id"
  end

  create_table "business_unit_kinds", force: :cascade do |t|
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["organization_id"], name: "index_business_unit_kinds_on_organization_id"
  end

  create_table "business_unit_scores", id: :serial, force: :cascade do |t|
    t.integer "design_score"
    t.integer "compliance_score"
    t.integer "sustantive_score"
    t.integer "business_unit_id"
    t.integer "control_objective_item_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_unit_id"], name: "index_business_unit_scores_on_business_unit_id"
    t.index ["control_objective_item_id"], name: "index_business_unit_scores_on_control_objective_item_id"
  end

  create_table "business_unit_type_reviews", force: :cascade do |t|
    t.bigint "business_unit_type_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["business_unit_type_id"], name: "index_business_unit_type_reviews_on_business_unit_type_id"
    t.index ["review_id"], name: "index_business_unit_type_reviews_on_review_id"
  end

  create_table "business_unit_type_users", force: :cascade do |t|
    t.bigint "business_unit_type_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["business_unit_type_id"], name: "index_business_unit_type_users_on_business_unit_type_id"
    t.index ["user_id"], name: "index_business_unit_type_users_on_user_id"
  end

  create_table "business_unit_types", id: :serial, force: :cascade do |t|
    t.string "name"
    t.boolean "external", default: false, null: false
    t.string "business_unit_label"
    t.string "project_label"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "review_prefix"
    t.boolean "require_tag", default: false, null: false
    t.text "sectors"
    t.text "recipients"
    t.boolean "require_counts", default: false, null: false
    t.boolean "hide_review_logo", default: false, null: false
    t.boolean "independent_identification", default: false, null: false
    t.boolean "shared_business_units", default: false, null: false
    t.index ["external"], name: "index_business_unit_types_on_external"
    t.index ["name"], name: "index_business_unit_types_on_name"
    t.index ["organization_id"], name: "index_business_unit_types_on_organization_id"
    t.index ["shared_business_units"], name: "index_business_unit_types_on_shared_business_units"
  end

  create_table "business_units", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "business_unit_type_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "business_unit_kind_id"
    t.index ["business_unit_kind_id"], name: "index_business_units_on_business_unit_kind_id"
    t.index ["business_unit_type_id"], name: "index_business_units_on_business_unit_type_id"
    t.index ["name"], name: "index_business_units_on_name"
  end

  create_table "closing_interview_users", force: :cascade do |t|
    t.string "kind", null: false
    t.bigint "closing_interview_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["closing_interview_id"], name: "index_closing_interview_users_on_closing_interview_id"
    t.index ["user_id"], name: "index_closing_interview_users_on_user_id"
  end

  create_table "closing_interviews", force: :cascade do |t|
    t.date "interview_date", null: false
    t.text "findings_summary"
    t.text "recommendations_summary"
    t.text "suggestions"
    t.text "comments"
    t.text "audit_comments"
    t.text "responsible_comments"
    t.integer "lock_version", default: 0, null: false
    t.bigint "review_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_date"], name: "index_closing_interviews_on_interview_date"
    t.index ["organization_id"], name: "index_closing_interviews_on_organization_id"
    t.index ["review_id"], name: "index_closing_interviews_on_review_id"
  end

  create_table "comments", id: :serial, force: :cascade do |t|
    t.text "comment"
    t.string "commentable_type"
    t.integer "commentable_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["commentable_id"], name: "index_comments_on_commentable_id"
    t.index ["commentable_type"], name: "index_comments_on_commentable_type"
    t.index ["user_id"], name: "index_comments_on_user_id"
  end

  create_table "commitment_supports", force: :cascade do |t|
    t.text "reason", null: false
    t.text "plan", null: false
    t.text "controls", null: false
    t.bigint "finding_answer_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["finding_answer_id"], name: "index_commitment_supports_on_finding_answer_id"
  end

  create_table "conclusion_reviews", id: :serial, force: :cascade do |t|
    t.string "type"
    t.integer "review_id"
    t.date "issue_date"
    t.date "close_date"
    t.text "applied_procedures"
    t.text "conclusion"
    t.boolean "approved"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.string "summary"
    t.text "recipients"
    t.text "sectors"
    t.string "evolution"
    t.text "evolution_justification"
    t.text "observations"
    t.text "main_weaknesses_text"
    t.text "corrective_actions"
    t.boolean "affects_compliance", default: false, null: false
    t.boolean "collapse_control_objectives", default: false, null: false
    t.integer "conclusion_index"
    t.text "reference"
    t.text "scope"
    t.string "previous_identification"
    t.date "previous_date"
    t.text "main_recommendations"
    t.text "effectiveness_notes"
    t.text "additional_comments"
    t.index ["close_date"], name: "index_conclusion_reviews_on_close_date"
    t.index ["conclusion_index"], name: "index_conclusion_reviews_on_conclusion_index"
    t.index ["issue_date"], name: "index_conclusion_reviews_on_issue_date"
    t.index ["organization_id"], name: "index_conclusion_reviews_on_organization_id"
    t.index ["review_id"], name: "index_conclusion_reviews_on_review_id"
    t.index ["summary"], name: "index_conclusion_reviews_on_summary"
    t.index ["type"], name: "index_conclusion_reviews_on_type"
  end

  create_table "control_objective_items", id: :serial, force: :cascade do |t|
    t.text "control_objective_text"
    t.integer "order_number"
    t.integer "relevance"
    t.integer "design_score"
    t.integer "compliance_score"
    t.integer "sustantive_score"
    t.date "audit_date"
    t.text "auditor_comment"
    t.boolean "finished"
    t.integer "control_objective_id"
    t.integer "review_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "exclude_from_score", default: false, null: false
    t.integer "organization_id"
    t.integer "issues_count"
    t.integer "alerts_count"
    t.index ["control_objective_id"], name: "index_control_objective_items_on_control_objective_id"
    t.index ["organization_id"], name: "index_control_objective_items_on_organization_id"
    t.index ["review_id"], name: "index_control_objective_items_on_review_id"
  end

  create_table "control_objective_projects", force: :cascade do |t|
    t.bigint "control_objective_id", null: false
    t.bigint "plan_item_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["control_objective_id"], name: "index_control_objective_projects_on_control_objective_id"
    t.index ["plan_item_id"], name: "index_control_objective_projects_on_plan_item_id"
  end

  create_table "control_objective_weakness_template_relations", force: :cascade do |t|
    t.bigint "control_objective_id", null: false
    t.bigint "weakness_template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["control_objective_id"], name: "index_co_wt_on_control_objective_id"
    t.index ["weakness_template_id"], name: "index_co_wt_on_weakness_template_id"
  end

  create_table "control_objectives", id: :serial, force: :cascade do |t|
    t.text "name"
    t.integer "risk"
    t.integer "relevance"
    t.integer "order"
    t.integer "process_control_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "obsolete", default: false
    t.string "support"
    t.string "score_type", default: "option", null: false
    t.index ["obsolete"], name: "index_control_objectives_on_obsolete"
    t.index ["process_control_id"], name: "index_control_objectives_on_process_control_id"
  end

  create_table "controls", id: :serial, force: :cascade do |t|
    t.text "control"
    t.text "effects"
    t.text "design_tests"
    t.text "compliance_tests"
    t.text "sustantive_tests"
    t.integer "order"
    t.string "controllable_type"
    t.integer "controllable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controllable_type", "controllable_id"], name: "index_controls_on_controllable_type_and_controllable_id"
  end

  create_table "costs", id: :serial, force: :cascade do |t|
    t.text "description"
    t.string "cost_type"
    t.decimal "cost", precision: 15, scale: 2
    t.string "item_type"
    t.integer "item_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.index ["created_at"], name: "index_e_mails_on_created_at"
    t.index ["organization_id"], name: "index_e_mails_on_organization_id"
  end

  create_table "endorsements", force: :cascade do |t|
    t.string "status", null: false
    t.bigint "user_id", null: false
    t.bigint "finding_answer_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "reason"
    t.index ["finding_answer_id"], name: "index_endorsements_on_finding_answer_id"
    t.index ["user_id"], name: "index_endorsements_on_user_id"
  end

  create_table "error_records", id: :serial, force: :cascade do |t|
    t.text "data"
    t.integer "error"
    t.integer "user_id"
    t.integer "organization_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_error_records_on_created_at"
    t.index ["organization_id"], name: "index_error_records_on_organization_id"
    t.index ["user_id"], name: "index_error_records_on_user_id"
  end

  create_table "file_model_reviews", force: :cascade do |t|
    t.bigint "file_model_id", null: false
    t.bigint "review_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["file_model_id"], name: "index_file_model_reviews_on_file_model_id"
    t.index ["review_id"], name: "index_file_model_reviews_on_review_id"
  end

  create_table "file_models", id: :serial, force: :cascade do |t|
    t.string "file_file_name"
    t.string "file_content_type"
    t.bigint "file_file_size"
    t.datetime "file_updated_at"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "finding_answers", id: :serial, force: :cascade do |t|
    t.text "answer"
    t.date "commitment_date"
    t.integer "finding_id"
    t.integer "user_id"
    t.integer "file_model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "skip_commitment_support", default: false, null: false
    t.boolean "imported", default: false, null: false
    t.index ["file_model_id"], name: "index_finding_answers_on_file_model_id"
    t.index ["finding_id"], name: "index_finding_answers_on_finding_id"
    t.index ["user_id"], name: "index_finding_answers_on_user_id"
  end

  create_table "finding_relations", id: :serial, force: :cascade do |t|
    t.string "description", null: false
    t.integer "finding_id"
    t.integer "related_finding_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["finding_id"], name: "index_finding_relations_on_finding_id"
    t.index ["related_finding_id"], name: "index_finding_relations_on_related_finding_id"
  end

  create_table "finding_review_assignments", id: :serial, force: :cascade do |t|
    t.integer "finding_id"
    t.integer "review_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["finding_id", "review_id"], name: "index_finding_review_assignments_on_finding_id_and_review_id"
  end

  create_table "finding_user_assignments", id: :serial, force: :cascade do |t|
    t.boolean "process_owner", default: false
    t.string "finding_type"
    t.integer "finding_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "responsible_auditor"
    t.index ["finding_id", "finding_type", "user_id"], name: "finding_user_assignments_on_id_type_and_user_id"
    t.index ["finding_id", "finding_type"], name: "index_finding_user_assignments_on_finding_id_and_finding_type"
  end

  create_table "findings", id: :serial, force: :cascade do |t|
    t.string "type"
    t.string "review_code"
    t.text "description"
    t.text "answer"
    t.text "audit_comments"
    t.date "solution_date"
    t.date "first_notification_date"
    t.date "confirmation_date"
    t.date "origination_date"
    t.boolean "final"
    t.integer "parent_id"
    t.integer "state"
    t.integer "notification_level", default: 0
    t.integer "lock_version", default: 0
    t.integer "control_objective_item_id"
    t.text "audit_recommendations"
    t.text "effect"
    t.integer "risk"
    t.integer "highest_risk"
    t.integer "priority"
    t.date "follow_up_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "repeated_of_id"
    t.integer "organization_id"
    t.string "title"
    t.text "current_situation"
    t.boolean "current_situation_verified", default: false, null: false
    t.string "compliance"
    t.text "operational_risk", default: [], array: true
    t.text "impact", default: [], null: false, array: true
    t.text "internal_control_components", default: [], null: false, array: true
    t.bigint "weakness_template_id"
    t.date "last_notification_date"
    t.integer "reschedule_count", default: 0, null: false
    t.integer "parent_ids", default: [], array: true
    t.date "implemented_at"
    t.date "closed_at"
    t.bigint "latest_id"
    t.date "first_follow_up_date"
    t.text "compliance_observations"
    t.jsonb "commitments"
    t.text "brief"
    t.integer "probability"
    t.integer "impact_risk"
    t.boolean "manual_risk", default: true, null: false
    t.boolean "use_suggested_impact", default: false, null: false
    t.boolean "use_suggested_probability", default: false, null: false
    t.decimal "impact_amount", precision: 17, scale: 2
    t.decimal "probability_amount", precision: 17, scale: 2
    t.index ["closed_at"], name: "index_findings_on_closed_at"
    t.index ["control_objective_item_id"], name: "index_findings_on_control_objective_item_id"
    t.index ["created_at"], name: "index_findings_on_created_at"
    t.index ["final"], name: "index_findings_on_final"
    t.index ["first_follow_up_date"], name: "index_findings_on_first_follow_up_date"
    t.index ["first_notification_date"], name: "index_findings_on_first_notification_date"
    t.index ["follow_up_date"], name: "index_findings_on_follow_up_date"
    t.index ["implemented_at"], name: "index_findings_on_implemented_at"
    t.index ["last_notification_date"], name: "index_findings_on_last_notification_date"
    t.index ["latest_id"], name: "index_findings_on_latest_id"
    t.index ["organization_id"], name: "index_findings_on_organization_id"
    t.index ["parent_id"], name: "index_findings_on_parent_id"
    t.index ["parent_ids"], name: "index_findings_on_parent_ids", using: :gin
    t.index ["repeated_of_id"], name: "index_findings_on_repeated_of_id"
    t.index ["reschedule_count"], name: "index_findings_on_reschedule_count"
    t.index ["state"], name: "index_findings_on_state"
    t.index ["title"], name: "index_findings_on_title"
    t.index ["type"], name: "index_findings_on_type"
    t.index ["updated_at"], name: "index_findings_on_updated_at"
    t.index ["weakness_template_id"], name: "index_findings_on_weakness_template_id"
  end

  create_table "groups", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "admin_email"
    t.string "admin_hash"
    t.text "description"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "licensed", default: false
    t.index ["admin_email"], name: "index_groups_on_admin_email", unique: true
    t.index ["admin_hash"], name: "index_groups_on_admin_hash", unique: true
    t.index ["name"], name: "index_groups_on_name", unique: true
  end

  create_table "image_models", id: :serial, force: :cascade do |t|
    t.string "image_file_name"
    t.string "image_content_type"
    t.integer "image_file_size"
    t.datetime "image_updated_at"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "imageable_type", null: false
    t.integer "imageable_id", null: false
    t.index ["imageable_type", "imageable_id"], name: "index_image_models_on_imageable_type_and_imageable_id"
  end

  create_table "issues", force: :cascade do |t|
    t.string "customer"
    t.string "entry"
    t.string "operation"
    t.decimal "amount", precision: 15, scale: 2
    t.text "comments"
    t.date "close_date"
    t.bigint "finding_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["finding_id"], name: "index_issues_on_finding_id"
  end

  create_table "ldap_configs", id: :serial, force: :cascade do |t|
    t.string "hostname", null: false
    t.integer "port", default: 389, null: false
    t.string "basedn", null: false
    t.string "login_mask", null: false
    t.string "username_attribute", null: false
    t.string "name_attribute", null: false
    t.string "last_name_attribute", null: false
    t.string "email_attribute", null: false
    t.string "function_attribute"
    t.string "roles_attribute", null: false
    t.string "manager_attribute"
    t.integer "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "filter"
    t.string "user"
    t.string "encrypted_password"
    t.string "alternative_hostname"
    t.integer "alternative_port"
    t.string "tls"
    t.string "ca_path"
    t.string "office_attribute"
    t.index ["organization_id"], name: "index_ldap_configs_on_organization_id"
  end

  create_table "licenses", force: :cascade do |t|
    t.bigint "group_id", null: false
    t.string "status", default: "trial", null: false
    t.integer "auditors_limit", null: false
    t.string "subscription_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.datetime "paid_until"
    t.index ["group_id"], name: "index_licenses_on_group_id"
    t.index ["paid_until"], name: "index_licenses_on_paid_until"
    t.index ["subscription_id"], name: "index_licenses_on_subscription_id"
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
    t.string "model_type"
    t.integer "model_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["model_type", "model_id"], name: "index_notification_relations_on_model_type_and_model_id"
    t.index ["notification_id"], name: "index_notification_relations_on_notification_id"
  end

  create_table "notifications", id: :serial, force: :cascade do |t|
    t.integer "status"
    t.string "confirmation_hash"
    t.text "notes"
    t.datetime "confirmation_date"
    t.integer "user_id"
    t.integer "user_who_confirm_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["confirmation_hash"], name: "index_notifications_on_confirmation_hash", unique: true
    t.index ["status"], name: "index_notifications_on_status"
    t.index ["user_id"], name: "index_notifications_on_user_id"
    t.index ["user_who_confirm_id"], name: "index_notifications_on_user_who_confirm_id"
  end

  create_table "old_passwords", id: :serial, force: :cascade do |t|
    t.string "password"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_old_passwords_on_created_at"
    t.index ["user_id"], name: "index_old_passwords_on_user_id"
  end

  create_table "opening_interview_users", force: :cascade do |t|
    t.string "kind", null: false
    t.bigint "opening_interview_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["opening_interview_id"], name: "index_opening_interview_users_on_opening_interview_id"
    t.index ["user_id"], name: "index_opening_interview_users_on_user_id"
  end

  create_table "opening_interviews", force: :cascade do |t|
    t.date "interview_date", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.text "objective", null: false
    t.text "program"
    t.text "scope"
    t.text "suggestions"
    t.text "comments"
    t.integer "lock_version", default: 0, null: false
    t.bigint "review_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interview_date"], name: "index_opening_interviews_on_interview_date"
    t.index ["organization_id"], name: "index_opening_interviews_on_organization_id"
    t.index ["review_id"], name: "index_opening_interviews_on_review_id"
  end

  create_table "organization_roles", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "organization_id"
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_organization_roles_on_organization_id"
    t.index ["role_id"], name: "index_organization_roles_on_role_id"
    t.index ["user_id"], name: "index_organization_roles_on_user_id"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "prefix"
    t.text "description"
    t.integer "group_id"
    t.integer "image_model_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "corporate", default: false, null: false
    t.string "logo_style", default: "default", null: false
    t.string "saml_provider"
    t.index ["corporate"], name: "index_organizations_on_corporate"
    t.index ["group_id"], name: "index_organizations_on_group_id"
    t.index ["image_model_id"], name: "index_organizations_on_image_model_id"
    t.index ["name"], name: "index_organizations_on_name"
    t.index ["prefix"], name: "index_organizations_on_prefix", unique: true
  end

  create_table "periods", id: :serial, force: :cascade do |t|
    t.text "description"
    t.date "start"
    t.date "end"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "name"
    t.index ["end"], name: "index_periods_on_end"
    t.index ["organization_id"], name: "index_periods_on_organization_id"
    t.index ["start"], name: "index_periods_on_start"
  end

  create_table "permalink_models", force: :cascade do |t|
    t.bigint "permalink_id", null: false
    t.string "model_type", null: false
    t.bigint "model_id", null: false
    t.datetime "created_at", null: false
    t.index ["model_type", "model_id"], name: "index_permalink_models_on_model_type_and_model_id"
    t.index ["permalink_id"], name: "index_permalink_models_on_permalink_id"
  end

  create_table "permalinks", force: :cascade do |t|
    t.string "token", null: false
    t.string "action", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.index ["organization_id"], name: "index_permalinks_on_organization_id"
    t.index ["token"], name: "index_permalinks_on_token", unique: true
  end

  create_table "plan_items", id: :serial, force: :cascade do |t|
    t.string "project"
    t.date "start"
    t.date "end"
    t.integer "order_number"
    t.integer "plan_id"
    t.integer "business_unit_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "risk_exposure"
    t.string "scope"
    t.index ["business_unit_id"], name: "index_plan_items_on_business_unit_id"
    t.index ["plan_id"], name: "index_plan_items_on_plan_id"
  end

  create_table "plans", id: :serial, force: :cascade do |t|
    t.integer "period_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "pollable_type"
    t.integer "pollable_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.string "access_token"
    t.integer "about_id"
    t.string "about_type"
    t.index ["about_id"], name: "index_polls_on_about_id"
    t.index ["about_type", "about_id"], name: "index_polls_on_about_type_and_about_id"
    t.index ["about_type"], name: "index_polls_on_about_type"
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
    t.boolean "approval", default: false
    t.integer "role_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["role_id"], name: "index_privileges_on_role_id"
  end

  create_table "process_controls", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "order"
    t.integer "best_practice_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "obsolete", default: false
    t.index ["best_practice_id"], name: "index_process_controls_on_best_practice_id"
    t.index ["obsolete"], name: "index_process_controls_on_obsolete"
  end

  create_table "questionnaires", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.string "pollable_type"
    t.string "email_subject"
    t.string "email_link"
    t.text "email_text"
    t.text "email_clarification"
    t.index ["name"], name: "index_questionnaires_on_name"
    t.index ["organization_id"], name: "index_questionnaires_on_organization_id"
  end

  create_table "questions", id: :serial, force: :cascade do |t|
    t.integer "sort_order"
    t.integer "answer_type"
    t.text "question"
    t.integer "questionnaire_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["questionnaire_id"], name: "index_questions_on_questionnaire_id"
  end

  create_table "readings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "readable_type", null: false
    t.bigint "readable_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_readings_on_organization_id"
    t.index ["readable_type", "readable_id"], name: "index_readings_on_readable_type_and_readable_id"
    t.index ["user_id"], name: "index_readings_on_user_id"
  end

  create_table "related_user_relations", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "related_user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "notify", default: false, null: false
    t.index ["user_id", "related_user_id"], name: "index_related_user_relations_on_user_id_and_related_user_id"
  end

  create_table "resource_classes", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "unit"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_resource_classes_on_name"
    t.index ["organization_id"], name: "index_resource_classes_on_organization_id"
  end

  create_table "resource_utilizations", id: :serial, force: :cascade do |t|
    t.decimal "units", precision: 15, scale: 2
    t.string "resource_consumer_type"
    t.integer "resource_consumer_id"
    t.string "resource_type"
    t.integer "resource_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_consumer_id", "resource_consumer_type"], name: "resource_utilizations_consumer_consumer_type_idx"
    t.index ["resource_id", "resource_type"], name: "resource_utilizations_resource_resource_type_idx"
  end

  create_table "resources", id: :serial, force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.integer "resource_class_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["resource_class_id"], name: "index_resources_on_resource_class_id"
  end

  create_table "review_user_assignments", id: :serial, force: :cascade do |t|
    t.integer "assignment_type"
    t.integer "review_id"
    t.integer "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "include_signature", default: true, null: false
    t.boolean "owner", default: false, null: false
    t.boolean "unavailable", default: false, null: false
    t.index ["review_id", "user_id"], name: "index_review_user_assignments_on_review_id_and_user_id"
  end

  create_table "reviews", id: :serial, force: :cascade do |t|
    t.string "identification"
    t.text "description"
    t.text "survey"
    t.integer "score"
    t.integer "top_scale"
    t.integer "achieved_scale"
    t.integer "period_id"
    t.integer "plan_item_id"
    t.integer "file_model_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.string "scope"
    t.string "risk_exposure"
    t.decimal "manual_score", precision: 6, scale: 2
    t.string "include_sox"
    t.integer "finished_work_papers", default: 0, null: false
    t.string "score_type", default: "effectiveness", null: false
    t.integer "score_alt", default: 100, null: false
    t.decimal "manual_score_alt", precision: 6, scale: 2
    t.index ["file_model_id"], name: "index_reviews_on_file_model_id"
    t.index ["identification"], name: "index_reviews_on_identification"
    t.index ["organization_id"], name: "index_reviews_on_organization_id"
    t.index ["period_id"], name: "index_reviews_on_period_id"
    t.index ["plan_item_id"], name: "index_reviews_on_plan_item_id"
  end

  create_table "risk_assessment_items", force: :cascade do |t|
    t.string "name", null: false
    t.integer "risk", null: false
    t.integer "order", default: 1, null: false
    t.bigint "business_unit_id"
    t.bigint "process_control_id"
    t.bigint "risk_assessment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["business_unit_id"], name: "index_risk_assessment_items_on_business_unit_id"
    t.index ["process_control_id"], name: "index_risk_assessment_items_on_process_control_id"
    t.index ["risk_assessment_id"], name: "index_risk_assessment_items_on_risk_assessment_id"
  end

  create_table "risk_assessment_templates", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "lock_version", default: 0, null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_risk_assessment_templates_on_organization_id"
  end

  create_table "risk_assessment_weights", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "weight", null: false
    t.bigint "risk_assessment_template_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["risk_assessment_template_id"], name: "index_risk_assessment_weights_on_risk_assessment_template_id"
  end

  create_table "risk_assessments", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "status", default: 0, null: false
    t.integer "lock_version", default: 0, null: false
    t.bigint "period_id", null: false
    t.bigint "plan_id"
    t.bigint "risk_assessment_template_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "file_model_id"
    t.boolean "shared", default: false, null: false
    t.bigint "group_id", null: false
    t.index ["file_model_id"], name: "index_risk_assessments_on_file_model_id"
    t.index ["group_id"], name: "index_risk_assessments_on_group_id"
    t.index ["organization_id"], name: "index_risk_assessments_on_organization_id"
    t.index ["period_id"], name: "index_risk_assessments_on_period_id"
    t.index ["plan_id"], name: "index_risk_assessments_on_plan_id"
    t.index ["risk_assessment_template_id"], name: "index_risk_assessments_on_risk_assessment_template_id"
    t.index ["shared"], name: "index_risk_assessments_on_shared"
  end

  create_table "risk_weights", force: :cascade do |t|
    t.integer "value"
    t.integer "weight", null: false
    t.bigint "risk_assessment_weight_id", null: false
    t.bigint "risk_assessment_item_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["risk_assessment_item_id"], name: "index_risk_weights_on_risk_assessment_item_id"
    t.index ["risk_assessment_weight_id"], name: "index_risk_weights_on_risk_assessment_weight_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.integer "role_type"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_roles_on_name"
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "name", null: false
    t.string "value", null: false
    t.text "description"
    t.integer "organization_id", null: false
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["name", "organization_id"], name: "index_settings_on_name_and_organization_id", unique: true
    t.index ["name"], name: "index_settings_on_name"
    t.index ["organization_id"], name: "index_settings_on_organization_id"
  end

  create_table "taggings", id: :serial, force: :cascade do |t|
    t.integer "tag_id", null: false
    t.string "taggable_type", null: false
    t.integer "taggable_id", null: false
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
    t.bigint "parent_id"
    t.boolean "obsolete", default: false, null: false
    t.index ["group_id"], name: "index_tags_on_group_id"
    t.index ["kind"], name: "index_tags_on_kind"
    t.index ["name"], name: "index_tags_on_name"
    t.index ["obsolete"], name: "index_tags_on_obsolete"
    t.index ["options"], name: "index_tags_on_options", using: :gin
    t.index ["organization_id"], name: "index_tags_on_organization_id"
    t.index ["parent_id"], name: "index_tags_on_parent_id"
    t.index ["shared"], name: "index_tags_on_shared"
  end

  create_table "tasks", force: :cascade do |t|
    t.text "description", null: false
    t.date "due_on", null: false
    t.integer "status", default: 0, null: false
    t.bigint "finding_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "code"
    t.index ["finding_id"], name: "index_tasks_on_finding_id"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", limit: 100
    t.string "last_name", limit: 100
    t.string "language", limit: 10
    t.string "email", limit: 100
    t.string "user", limit: 30
    t.string "function"
    t.string "password", limit: 128
    t.string "salt"
    t.string "change_password_hash"
    t.date "password_changed"
    t.boolean "enable", default: false
    t.boolean "logged_in", default: false
    t.boolean "group_admin", default: false
    t.datetime "last_access"
    t.integer "manager_id"
    t.integer "failed_attempts", default: 0
    t.text "notes"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "hash_changed"
    t.boolean "hidden", default: false
    t.string "organizational_unit"
    t.string "office"
    t.index ["change_password_hash"], name: "index_users_on_change_password_hash", unique: true
    t.index ["email"], name: "index_users_on_email"
    t.index ["group_admin"], name: "index_users_on_group_admin"
    t.index ["hidden"], name: "index_users_on_hidden"
    t.index ["manager_id"], name: "index_users_on_manager_id"
    t.index ["user"], name: "index_users_on_user"
  end

  create_table "versions", id: :serial, force: :cascade do |t|
    t.string "item_type"
    t.integer "item_id"
    t.string "event", null: false
    t.integer "whodunnit"
    t.datetime "created_at"
    t.boolean "important"
    t.integer "organization_id"
    t.jsonb "object"
    t.jsonb "object_changes"
    t.index ["created_at"], name: "index_versions_on_created_at"
    t.index ["important"], name: "index_versions_on_important"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
    t.index ["object_changes"], name: "index_versions_on_object_changes", using: :gin
    t.index ["organization_id"], name: "index_versions_on_organization_id"
    t.index ["whodunnit"], name: "index_versions_on_whodunnit"
  end

  create_table "weakness_templates", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.integer "risk"
    t.text "impact", default: [], null: false, array: true
    t.text "operational_risk", default: [], null: false, array: true
    t.text "internal_control_components", default: [], null: false, array: true
    t.integer "lock_version", default: 0, null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reference"
    t.text "notes"
    t.index ["organization_id"], name: "index_weakness_templates_on_organization_id"
    t.index ["reference"], name: "index_weakness_templates_on_reference"
  end

  create_table "webhooks", force: :cascade do |t|
    t.string "gateway", null: false
    t.string "status", null: false
    t.string "kind", null: false
    t.string "reference_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["gateway"], name: "index_webhooks_on_gateway"
    t.index ["status"], name: "index_webhooks_on_status"
  end

  create_table "work_papers", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "code"
    t.integer "number_of_pages"
    t.text "description"
    t.string "owner_type"
    t.integer "owner_id"
    t.integer "file_model_id"
    t.integer "organization_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["workflow_id"], name: "index_workflow_items_on_workflow_id"
  end

  create_table "workflows", id: :serial, force: :cascade do |t|
    t.integer "review_id"
    t.integer "period_id"
    t.integer "lock_version", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "organization_id"
    t.bigint "file_model_id"
    t.index ["file_model_id"], name: "index_workflows_on_file_model_id"
    t.index ["organization_id"], name: "index_workflows_on_organization_id"
    t.index ["period_id"], name: "index_workflows_on_period_id"
    t.index ["review_id"], name: "index_workflows_on_review_id"
  end

  add_foreign_key "achievements", "benefits", on_update: :restrict, on_delete: :restrict
  add_foreign_key "achievements", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "benefits", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practice_comments", "best_practices", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practice_comments", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practice_projects", "best_practices", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practice_projects", "plan_items", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practices", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "best_practices", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_findings", "business_units", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_findings", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_kinds", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_scores", "business_units", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_scores", "control_objective_items", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_type_reviews", "business_unit_types", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_type_reviews", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_type_users", "business_unit_types", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_type_users", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_unit_types", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_units", "business_unit_kinds", on_update: :restrict, on_delete: :restrict
  add_foreign_key "business_units", "business_unit_types", on_update: :restrict, on_delete: :restrict
  add_foreign_key "closing_interview_users", "closing_interviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "closing_interview_users", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "closing_interviews", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "closing_interviews", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "comments", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "commitment_supports", "finding_answers", on_update: :restrict, on_delete: :restrict
  add_foreign_key "conclusion_reviews", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objective_items", "control_objectives", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objective_items", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objective_projects", "control_objectives", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objective_projects", "plan_items", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objective_weakness_template_relations", "control_objectives", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objective_weakness_template_relations", "weakness_templates", on_update: :restrict, on_delete: :restrict
  add_foreign_key "control_objectives", "process_controls", on_update: :restrict, on_delete: :restrict
  add_foreign_key "costs", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "documents", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "documents", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "documents", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "endorsements", "finding_answers", on_update: :restrict, on_delete: :restrict
  add_foreign_key "endorsements", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "error_records", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "error_records", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "file_model_reviews", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "file_model_reviews", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_answers", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_answers", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_answers", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_relations", "findings", column: "related_finding_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_relations", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_review_assignments", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_review_assignments", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_user_assignments", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "finding_user_assignments", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "findings", "control_objective_items", on_update: :restrict, on_delete: :restrict
  add_foreign_key "findings", "findings", column: "latest_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "findings", "findings", column: "repeated_of_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "findings", "weakness_templates", on_update: :restrict, on_delete: :restrict
  add_foreign_key "issues", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "ldap_configs", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "licenses", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "login_records", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "login_records", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "news", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "news", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notification_relations", "notifications", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notifications", "users", column: "user_who_confirm_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "notifications", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "old_passwords", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "opening_interview_users", "opening_interviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "opening_interview_users", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "opening_interviews", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "opening_interviews", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "organization_roles", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "organization_roles", "roles", on_update: :restrict, on_delete: :restrict
  add_foreign_key "organization_roles", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "organizations", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "organizations", "image_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "periods", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "permalink_models", "permalinks", on_update: :restrict, on_delete: :restrict
  add_foreign_key "permalinks", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plan_items", "business_units", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plan_items", "plans", on_update: :restrict, on_delete: :restrict
  add_foreign_key "plans", "periods", on_update: :restrict, on_delete: :restrict
  add_foreign_key "polls", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "polls", "questionnaires", on_update: :restrict, on_delete: :restrict
  add_foreign_key "polls", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "privileges", "roles", on_update: :restrict, on_delete: :restrict
  add_foreign_key "process_controls", "best_practices", on_update: :restrict, on_delete: :restrict
  add_foreign_key "readings", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "readings", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "resource_classes", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "resources", "resource_classes", on_update: :restrict, on_delete: :restrict
  add_foreign_key "review_user_assignments", "reviews", on_update: :restrict, on_delete: :restrict
  add_foreign_key "review_user_assignments", "users", on_update: :restrict, on_delete: :restrict
  add_foreign_key "reviews", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "reviews", "periods", on_update: :restrict, on_delete: :restrict
  add_foreign_key "reviews", "plan_items", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessment_items", "business_units", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessment_items", "process_controls", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessment_items", "risk_assessments", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessment_templates", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessment_weights", "risk_assessment_templates", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessments", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessments", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessments", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessments", "periods", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessments", "plans", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_assessments", "risk_assessment_templates", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_weights", "risk_assessment_items", on_update: :restrict, on_delete: :restrict
  add_foreign_key "risk_weights", "risk_assessment_weights", on_update: :restrict, on_delete: :restrict
  add_foreign_key "roles", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "settings", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "taggings", "tags", on_update: :restrict, on_delete: :restrict
  add_foreign_key "tags", "groups", on_update: :restrict, on_delete: :restrict
  add_foreign_key "tags", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "tasks", "findings", on_update: :restrict, on_delete: :restrict
  add_foreign_key "users", "users", column: "manager_id", on_update: :restrict, on_delete: :restrict
  add_foreign_key "weakness_templates", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "work_papers", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "work_papers", "organizations", on_update: :restrict, on_delete: :restrict
  add_foreign_key "workflow_items", "workflows", on_update: :restrict, on_delete: :restrict
  add_foreign_key "workflows", "file_models", on_update: :restrict, on_delete: :restrict
  add_foreign_key "workflows", "periods", on_update: :restrict, on_delete: :restrict
  add_foreign_key "workflows", "reviews", on_update: :restrict, on_delete: :restrict
end
