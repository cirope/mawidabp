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

ActiveRecord::Schema.define(version: 20160131223829) do

  create_table "achievements", force: :cascade do |t|
    t.integer  "benefit_id", limit: nil,                          null: false
    t.decimal  "amount",                 precision: 15, scale: 2
    t.text     "comment"
    t.integer  "finding_id", limit: nil,                          null: false
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
  end

  add_index "achievements", ["benefit_id"], name: "i_achievements_benefit_id"
  add_index "achievements", ["finding_id"], name: "i_achievements_finding_id"

  create_table "answer_options", force: :cascade do |t|
    t.text     "option"
    t.integer  "question_id",  limit: nil
    t.integer  "lock_version",             precision: 38, default: 0
    t.datetime "created_at",                                          null: false
    t.datetime "updated_at",                                          null: false
  end

  add_index "answer_options", ["question_id"], name: "i_answer_options_question_id"

  create_table "answers", force: :cascade do |t|
    t.text     "comments"
    t.string   "type"
    t.integer  "question_id",      limit: nil
    t.integer  "poll_id",          limit: nil
    t.integer  "lock_version",                 precision: 38, default: 0
    t.text     "answer"
    t.integer  "answer_option_id", limit: nil
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  add_index "answers", ["poll_id"], name: "index_answers_on_poll_id"
  add_index "answers", ["question_id"], name: "index_answers_on_question_id"
  add_index "answers", ["type", "id"], name: "index_answers_on_type_and_id"

  create_table "aq$_internet_agent_privs", id: false, force: :cascade do |t|
    t.string "agent_name",  limit: 30, null: false
    t.string "db_username", limit: 30, null: false
  end

  add_index "aq$_internet_agent_privs", ["agent_name", "db_username"], name: "unq_pairs", unique: true

  create_table "aq$_internet_agents", primary_key: "agent_name", force: :cascade do |t|
    t.integer "protocol",             precision: 38, null: false
    t.string  "spare1",   limit: 128
  end

  create_table "aq$_queue_tables", primary_key: "objno", force: :cascade do |t|
    t.string  "schema",        limit: 30,   null: false
    t.string  "name",          limit: 30,   null: false
    t.decimal "udata_type",                 null: false
    t.decimal "flags",                      null: false
    t.decimal "sort_cols",                  null: false
    t.string  "timezone",      limit: 64
    t.string  "table_comment", limit: 2000
  end

  add_index "aq$_queue_tables", ["objno", "schema", "flags"], name: "i1_queue_tables"

# Could not dump table "aq$_queues" because of following StandardError
#   Unknown type 'SYS.AQ$_SUBSCRIBERS' for column 'subscribers'

  create_table "aq$_schedules", id: false, force: :cascade do |t|
    t.raw      "oid",         limit: 16,  null: false
    t.string   "destination", limit: 128, null: false
    t.datetime "start_time"
    t.string   "duration",    limit: 8
    t.string   "next_time",   limit: 128
    t.string   "latency",     limit: 8
    t.datetime "last_time"
    t.decimal  "jobno"
  end

  add_index "aq$_schedules", ["jobno"], name: "aq$_schedules_check", unique: true

  create_table "benefits", force: :cascade do |t|
    t.string   "name",                        null: false
    t.string   "kind",                        null: false
    t.integer  "organization_id", limit: nil, null: false
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "benefits", ["organization_id"], name: "i_benefits_organization_id"

  create_table "best_practices", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.integer  "organization_id", limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.boolean  "obsolete",        limit: nil,                default: false
    t.boolean  "shared",          limit: nil,                default: false
    t.integer  "group_id",        limit: nil
  end

  add_index "best_practices", ["created_at"], name: "i_best_practices_created_at"
  add_index "best_practices", ["group_id"], name: "i_best_practices_group_id"
  add_index "best_practices", ["obsolete"], name: "i_best_practices_obsolete"
  add_index "best_practices", ["organization_id"], name: "i_bes_pra_org_id"

  create_table "business_unit_findings", force: :cascade do |t|
    t.integer  "business_unit_id", limit: nil
    t.integer  "finding_id",       limit: nil
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "business_unit_findings", ["business_unit_id"], name: "i_bus_uni_fin_bus_uni_id"
  add_index "business_unit_findings", ["finding_id"], name: "i_bus_uni_fin_fin_id"

  create_table "business_unit_scores", force: :cascade do |t|
    t.integer  "design_score",                          precision: 38
    t.integer  "compliance_score",                      precision: 38
    t.integer  "sustantive_score",                      precision: 38
    t.integer  "business_unit_id",          limit: nil
    t.integer  "control_objective_item_id", limit: nil
    t.datetime "created_at",                                           null: false
    t.datetime "updated_at",                                           null: false
  end

  add_index "business_unit_scores", ["business_unit_id"], name: "i_bus_uni_sco_bus_uni_id"
  add_index "business_unit_scores", ["control_objective_item_id"], name: "i_bus_uni_sco_con_obj_ite_id"

  create_table "business_unit_types", force: :cascade do |t|
    t.string   "name"
    t.boolean  "external",            limit: nil,                default: false, null: false
    t.string   "business_unit_label"
    t.string   "project_label"
    t.integer  "organization_id",     limit: nil
    t.integer  "lock_version",                    precision: 38, default: 0
    t.datetime "created_at",                                                     null: false
    t.datetime "updated_at",                                                     null: false
  end

  add_index "business_unit_types", ["external"], name: "i_business_unit_types_external"
  add_index "business_unit_types", ["name"], name: "i_business_unit_types_name"
  add_index "business_unit_types", ["organization_id"], name: "i_bus_uni_typ_org_id"

  create_table "business_units", force: :cascade do |t|
    t.string   "name"
    t.integer  "business_unit_type_id", limit: nil
    t.datetime "created_at",                        null: false
    t.datetime "updated_at",                        null: false
  end

  add_index "business_units", ["business_unit_type_id"], name: "i_bus_uni_bus_uni_typ_id"
  add_index "business_units", ["name"], name: "index_business_units_on_name"

  create_table "comments", force: :cascade do |t|
    t.text     "comment"
    t.integer  "commentable_id",   limit: nil
    t.string   "commentable_type"
    t.integer  "user_id",          limit: nil
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "comments", ["commentable_id"], name: "i_comments_commentable_id"
  add_index "comments", ["commentable_type"], name: "i_comments_commentable_type"
  add_index "comments", ["user_id"], name: "index_comments_on_user_id"

  create_table "conclusion_reviews", force: :cascade do |t|
    t.string   "type"
    t.integer  "review_id",          limit: nil
    t.date     "issue_date"
    t.date     "close_date"
    t.text     "applied_procedures"
    t.text     "conclusion"
    t.boolean  "approved",           limit: nil
    t.integer  "lock_version",                   precision: 38, default: 0
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.integer  "organization_id",    limit: nil
  end

  add_index "conclusion_reviews", ["close_date"], name: "i_con_rev_clo_dat"
  add_index "conclusion_reviews", ["issue_date"], name: "i_con_rev_iss_dat"
  add_index "conclusion_reviews", ["organization_id"], name: "i_con_rev_org_id"
  add_index "conclusion_reviews", ["review_id"], name: "i_conclusion_reviews_review_id"
  add_index "conclusion_reviews", ["type"], name: "i_conclusion_reviews_type"

  create_table "control_objective_items", force: :cascade do |t|
    t.text     "control_objective_text"
    t.integer  "order_number",                       precision: 38
    t.integer  "relevance",                          precision: 38
    t.integer  "design_score",                       precision: 38
    t.integer  "compliance_score",                   precision: 38
    t.integer  "sustantive_score",                   precision: 38
    t.date     "audit_date"
    t.text     "auditor_comment"
    t.boolean  "finished",               limit: nil
    t.integer  "control_objective_id",   limit: nil
    t.integer  "review_id",              limit: nil
    t.integer  "lock_version",                       precision: 38, default: 0
    t.datetime "created_at",                                                        null: false
    t.datetime "updated_at",                                                        null: false
    t.boolean  "exclude_from_score",     limit: nil,                default: false, null: false
    t.integer  "organization_id",        limit: nil
  end

  add_index "control_objective_items", ["control_objective_id"], name: "i_con_obj_ite_con_obj_id"
  add_index "control_objective_items", ["organization_id"], name: "i_con_obj_ite_org_id"
  add_index "control_objective_items", ["review_id"], name: "i_con_obj_ite_rev_id"

  create_table "control_objectives", force: :cascade do |t|
    t.text     "name"
    t.integer  "risk",                           precision: 38
    t.integer  "relevance",                      precision: 38
    t.integer  "order",                          precision: 38
    t.integer  "process_control_id", limit: nil
    t.datetime "created_at",                                                    null: false
    t.datetime "updated_at",                                                    null: false
    t.boolean  "obsolete",           limit: nil,                default: false
    t.boolean  "continuous",         limit: nil
  end

  add_index "control_objectives", ["obsolete"], name: "i_control_objectives_obsolete"
  add_index "control_objectives", ["process_control_id"], name: "i_con_obj_pro_con_id"

  create_table "controls", force: :cascade do |t|
    t.text     "control"
    t.text     "effects"
    t.text     "design_tests"
    t.text     "compliance_tests"
    t.text     "sustantive_tests"
    t.integer  "order",                         precision: 38
    t.integer  "controllable_id",   limit: nil
    t.string   "controllable_type"
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  add_index "controls", ["controllable_type", "controllable_id"], name: "i_con_con_typ_con_id"

  create_table "costs", force: :cascade do |t|
    t.text     "description"
    t.string   "cost_type"
    t.decimal  "cost",                    precision: 15, scale: 2
    t.integer  "item_id",     limit: nil
    t.string   "item_type"
    t.integer  "user_id",     limit: nil
    t.datetime "created_at",                                       null: false
    t.datetime "updated_at",                                       null: false
  end

  add_index "costs", ["cost_type"], name: "index_costs_on_cost_type"
  add_index "costs", ["item_type", "item_id"], name: "i_costs_item_type_item_id"
  add_index "costs", ["user_id"], name: "index_costs_on_user_id"

  create_table "def$_aqcall", id: false, force: :cascade do |t|
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

  create_table "def$_aqerror", id: false, force: :cascade do |t|
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

  create_table "def$_calldest", comment: "Information about call destinations for D-type and error transactions", id: false, force: :cascade do |t|
    t.string  "enq_tid",      limit: 22,                 null: false, comment: "Transaction ID"
    t.decimal "step_no",                                 null: false, comment: "Unique ID of call within transaction"
    t.string  "dblink",       limit: 128,                null: false, comment: "The destination database"
    t.string  "schema_name",  limit: 30,                              comment: "The schema of the deferred remote procedure call"
    t.string  "package_name", limit: 30,                              comment: "The package of the deferred remote procedure call"
    t.raw     "catchup",      limit: 16,  default: "00",              comment: "Dummy column for foreign key"
  end

  add_index "def$_calldest", ["dblink", "catchup"], name: "def$_calldest_n2"

  create_table "def$_defaultdest", comment: "Default destinations for deferred remote procedure calls", primary_key: "dblink", force: :cascade do |t|
  end

  create_table "def$_destination", comment: "Information about propagation to different destinations", id: false, force: :cascade do |t|
    t.string  "dblink",                     limit: 128,                       null: false, comment: "Destination"
    t.decimal "last_delivered",                          default: 0.0,        null: false, comment: "Value of delivery_order of last transaction propagated"
    t.string  "last_enq_tid",               limit: 22,                                     comment: "Transaction ID of last transaction propagated"
    t.decimal "last_seq",                                                                  comment: "Parallel prop seq number of last transaction propagated"
    t.boolean "disabled",                   limit: nil,                                    comment: "Is propagation to destination disabled"
    t.decimal "job",                                                                       comment: "Number of job that pushes queue"
    t.decimal "last_txn_count",                                                            comment: "Number of transactions pushed during last attempt"
    t.decimal "last_error_number",                                                         comment: "Oracle error number from last push"
    t.string  "last_error_message",         limit: 2000,                                   comment: "Error message from last push"
    t.string  "apply_init",                 limit: 4000
    t.raw     "catchup",                    limit: 16,   default: "00",       null: false, comment: "Used to break transaction into pieces"
    t.boolean "alternate",                  limit: nil,  default: false,                   comment: "Used to break transaction into pieces"
    t.decimal "total_txn_count",                         default: 0.0,                     comment: "Total number of transactions pushed"
    t.decimal "total_prop_time_throughput",              default: 0.0,                     comment: "Total propagation time in seconds for measuring throughput"
    t.decimal "total_prop_time_latency",                 default: 0.0,                     comment: "Total propagation time in seconds for measuring latency"
    t.decimal "to_communication_size",                   default: 0.0,                     comment: "Total number of bytes sent to this dblink"
    t.decimal "from_communication_size",                 default: 0.0,                     comment: "Total number of bytes received from this dblink"
    t.raw     "flag",                       limit: 4,    default: "00000000"
    t.decimal "spare1",                                  default: 0.0,                     comment: "Total number of round trips for this dblink"
    t.decimal "spare2",                                  default: 0.0,                     comment: "Total number of administrative requests"
    t.decimal "spare3",                                  default: 0.0,                     comment: "Total number of error transactions pushed"
    t.decimal "spare4",                                  default: 0.0,                     comment: "Total time in seconds spent sleeping during push"
  end

  create_table "def$_error", comment: "Information about all deferred transactions that caused an error", primary_key: "enq_tid", force: :cascade do |t|
    t.string   "origin_tran_db", limit: 128,  comment: "The database originating the deferred transaction"
    t.string   "origin_enq_tid", limit: 22,   comment: "The original ID of the transaction"
    t.string   "destination",    limit: 128,  comment: "Database link used to address destination"
    t.decimal  "step_no",                     comment: "Unique ID of call that caused an error"
    t.decimal  "receiver",                    comment: "User ID of the original receiver"
    t.datetime "enq_time",                    comment: "Time original transaction enqueued"
    t.decimal  "error_number",                comment: "Oracle error number"
    t.string   "error_msg",      limit: 2000, comment: "Error message text"
  end

  create_table "def$_lob", comment: "Storage for LOB parameters to deferred RPCs", force: :cascade do |t|
    t.string "enq_tid",   limit: 22, comment: "Transaction identifier for deferred RPC with this LOB parameter"
    t.binary "blob_col",             comment: "Binary LOB parameter"
    t.text   "clob_col",             comment: "Character LOB parameter"
    t.text   "nclob_col",            comment: "National Character LOB parameter"
  end

  add_index "def$_lob", ["enq_tid"], name: "def$_lob_n1"

  create_table "def$_origin", comment: "Information about deferred transactions pushed to this site", id: false, force: :cascade do |t|
    t.string  "origin_db",     limit: 128,                comment: "Originating database for the deferred transaction"
    t.string  "origin_dblink", limit: 128,                comment: "Database link from deferred transaction origin to this site"
    t.decimal "inusr",                                    comment: "Connected user receiving the deferred transaction"
    t.decimal "cscn",                                     comment: "Prepare SCN assigned at origin site"
    t.string  "enq_tid",       limit: 22,                 comment: "Transaction id assigned at origin site"
    t.decimal "reco_seq_no",                              comment: "Deferred transaction sequence number for recovery"
    t.raw     "catchup",       limit: 16,  default: "00", comment: "Used to break transaction into pieces"
  end

  create_table "def$_propagator", comment: "The propagator for deferred remote procedure calls", primary_key: "userid", force: :cascade do |t|
    t.string   "username", limit: 30, null: false, comment: "User name of the propagator"
    t.datetime "created",             null: false, comment: "The time when the propagator is registered"
  end

  create_table "def$_pushed_transactions", comment: "Information about deferred transactions pushed to this site by RepAPI clients", primary_key: "source_site_id", force: :cascade do |t|
    t.integer "last_tran_id", limit: nil, default: 0,     comment: "Last committed transaction"
    t.boolean "disabled",     limit: nil, default: false, comment: "Disable propagation"
    t.string  "source_site",  limit: 128,                 comment: "Obsolete - do not use"
  end

  create_table "e_mails", force: :cascade do |t|
    t.text     "to"
    t.text     "subject"
    t.text     "body"
    t.text     "attachments"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
    t.integer  "organization_id", limit: nil
  end

  add_index "e_mails", ["created_at"], name: "index_e_mails_on_created_at"
  add_index "e_mails", ["organization_id"], name: "i_e_mails_organization_id"

  create_table "error_records", force: :cascade do |t|
    t.text     "data"
    t.integer  "error",                       precision: 38
    t.integer  "user_id",         limit: nil
    t.integer  "organization_id", limit: nil
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "error_records", ["created_at"], name: "i_error_records_created_at"
  add_index "error_records", ["organization_id"], name: "i_err_rec_org_id"
  add_index "error_records", ["user_id"], name: "index_error_records_on_user_id"

  create_table "file_models", force: :cascade do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size",    precision: 38
    t.datetime "file_updated_at"
    t.integer  "lock_version",      precision: 38, default: 0
    t.datetime "created_at",                                   null: false
    t.datetime "updated_at",                                   null: false
  end

  create_table "finding_answers", force: :cascade do |t|
    t.text     "answer"
    t.text     "auditor_comments"
    t.date     "commitment_date"
    t.integer  "finding_id",       limit: nil
    t.integer  "user_id",          limit: nil
    t.integer  "file_model_id",    limit: nil
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
  end

  add_index "finding_answers", ["file_model_id"], name: "i_fin_ans_fil_mod_id"
  add_index "finding_answers", ["finding_id"], name: "i_finding_answers_finding_id"
  add_index "finding_answers", ["user_id"], name: "i_finding_answers_user_id"

  create_table "finding_relations", force: :cascade do |t|
    t.string   "description",                    null: false
    t.integer  "finding_id",         limit: nil
    t.integer  "related_finding_id", limit: nil
    t.datetime "created_at",                     null: false
    t.datetime "updated_at",                     null: false
  end

  add_index "finding_relations", ["finding_id"], name: "i_finding_relations_finding_id"
  add_index "finding_relations", ["related_finding_id"], name: "i_fin_rel_rel_fin_id"

  create_table "finding_review_assignments", force: :cascade do |t|
    t.integer  "finding_id", limit: nil
    t.integer  "review_id",  limit: nil
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "finding_review_assignments", ["finding_id", "review_id"], name: "i_fin_rev_ass_fin_id_rev_id"

  create_table "finding_user_assignments", force: :cascade do |t|
    t.boolean  "process_owner",       limit: nil, default: false
    t.integer  "finding_id",          limit: nil
    t.string   "finding_type"
    t.integer  "user_id",             limit: nil
    t.datetime "created_at",                                      null: false
    t.datetime "updated_at",                                      null: false
    t.boolean  "responsible_auditor", limit: nil
  end

  add_index "finding_user_assignments", ["finding_id", "finding_type", "user_id"], name: "fua_on_id_type_and_user_id"
  add_index "finding_user_assignments", ["finding_id", "finding_type"], name: "i_fin_use_ass_fin_id_fin_typ"

  create_table "findings", force: :cascade do |t|
    t.string   "type"
    t.string   "review_code"
    t.text     "description"
    t.text     "answer"
    t.text     "audit_comments"
    t.date     "solution_date"
    t.date     "first_notification_date"
    t.date     "confirmation_date"
    t.date     "origination_date"
    t.boolean  "final",                     limit: nil
    t.integer  "parent_id",                 limit: nil
    t.integer  "state",                                 precision: 38
    t.integer  "notification_level",                    precision: 38, default: 0
    t.integer  "lock_version",                          precision: 38, default: 0
    t.integer  "control_objective_item_id", limit: nil
    t.text     "audit_recommendations"
    t.text     "effect"
    t.integer  "risk",                                  precision: 38
    t.integer  "highest_risk",                          precision: 38
    t.integer  "priority",                              precision: 38
    t.date     "follow_up_date"
    t.datetime "created_at",                                                       null: false
    t.datetime "updated_at",                                                       null: false
    t.integer  "repeated_of_id",            limit: nil
    t.integer  "organization_id",           limit: nil
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
  add_index "findings", ["title"], name: "index_findings_on_title"
  add_index "findings", ["type"], name: "index_findings_on_type"
  add_index "findings", ["updated_at"], name: "index_findings_on_updated_at"

  create_table "groups", force: :cascade do |t|
    t.string   "name"
    t.string   "admin_email"
    t.string   "admin_hash"
    t.text     "description"
    t.integer  "lock_version", precision: 38, default: 0
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "groups", ["admin_email"], name: "index_groups_on_admin_email", unique: true
  add_index "groups", ["admin_hash"], name: "index_groups_on_admin_hash", unique: true
  add_index "groups", ["name"], name: "index_groups_on_name", unique: true

  create_table "help", id: false, force: :cascade do |t|
    t.string  "topic", limit: 50, null: false
    t.decimal "seq",              null: false
    t.string  "info",  limit: 80
  end

  create_table "image_models", force: :cascade do |t|
    t.string   "image_file_name"
    t.string   "image_content_type"
    t.integer  "image_file_size",    precision: 38
    t.datetime "image_updated_at"
    t.integer  "lock_version",       precision: 38, default: 0
    t.datetime "created_at",                                    null: false
    t.datetime "updated_at",                                    null: false
  end

  create_table "ldap_configs", force: :cascade do |t|
    t.string   "hostname",                                                     null: false
    t.integer  "port",                            precision: 38, default: 389, null: false
    t.string   "basedn",                                                       null: false
    t.string   "login_mask",                                                   null: false
    t.string   "username_attribute",                                           null: false
    t.string   "name_attribute",                                               null: false
    t.string   "last_name_attribute",                                          null: false
    t.string   "email_attribute",                                              null: false
    t.string   "function_attribute"
    t.string   "roles_attribute",                                              null: false
    t.string   "manager_attribute"
    t.integer  "organization_id",     limit: nil,                              null: false
    t.datetime "created_at",                                                   null: false
    t.datetime "updated_at",                                                   null: false
    t.string   "filter"
  end

  add_index "ldap_configs", ["organization_id"], name: "i_ldap_configs_organization_id"

  create_table "login_records", force: :cascade do |t|
    t.integer  "user_id",         limit: nil
    t.text     "data"
    t.datetime "start"
    t.datetime "end"
    t.datetime "created_at"
    t.integer  "organization_id", limit: nil
  end

  add_index "login_records", ["end"], name: "index_login_records_on_end"
  add_index "login_records", ["organization_id"], name: "i_log_rec_org_id"
  add_index "login_records", ["start"], name: "index_login_records_on_start"
  add_index "login_records", ["user_id"], name: "index_login_records_on_user_id"

  create_table "logmnr_age_spill$", id: false, force: :cascade do |t|
    t.decimal "session#",   null: false
    t.decimal "xidusn",     null: false
    t.decimal "xidslt",     null: false
    t.decimal "xidsqn",     null: false
    t.decimal "chunk",      null: false
    t.decimal "sequence#",  null: false
    t.decimal "offset"
    t.binary  "spill_data"
    t.decimal "spare1"
    t.decimal "spare2"
  end

  create_table "logmnr_attrcol$", id: false, force: :cascade do |t|
    t.decimal "intcol#"
    t.string  "name",         limit: 4000
    t.decimal "obj#",                                     null: false
    t.integer "logmnr_uid",   limit: 22,   precision: 22
    t.integer "logmnr_flags", limit: 22,   precision: 22
  end

  add_index "logmnr_attrcol$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1attrcol$"

  create_table "logmnr_attribute$", id: false, force: :cascade do |t|
    t.decimal "version#"
    t.string  "name",          limit: 30
    t.decimal "attribute#"
    t.raw     "attr_toid",     limit: 16
    t.decimal "attr_version#"
    t.decimal "synobj#"
    t.decimal "properties"
    t.decimal "charsetid"
    t.decimal "charsetform"
    t.decimal "length"
    t.decimal "precision#"
    t.decimal "scale"
    t.string  "externname",    limit: 4000
    t.decimal "xflags"
    t.decimal "spare1"
    t.decimal "spare2"
    t.decimal "spare3"
    t.decimal "spare4"
    t.decimal "spare5"
    t.decimal "setter"
    t.decimal "getter"
    t.raw     "toid",          limit: 16,                  null: false
    t.integer "logmnr_uid",    limit: 22,   precision: 22
    t.integer "logmnr_flags",  limit: 22,   precision: 22
  end

  add_index "logmnr_attribute$", ["logmnr_uid", "toid", "version#", "attribute#"], name: "logmnr_i1attribute$"

  create_table "logmnr_ccol$", id: false, force: :cascade do |t|
    t.decimal "con#"
    t.decimal "obj#"
    t.decimal "col#"
    t.decimal "pos#"
    t.decimal "intcol#",                                null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_ccol$", ["logmnr_uid", "con#", "intcol#"], name: "logmnr_i1ccol$"

  create_table "logmnr_cdef$", id: false, force: :cascade do |t|
    t.decimal "con#"
    t.decimal "cols"
    t.decimal "type#"
    t.decimal "robj#"
    t.decimal "rcon#"
    t.decimal "enabled"
    t.decimal "defer"
    t.decimal "obj#",                                   null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_cdef$", ["logmnr_uid", "con#"], name: "logmnr_i1cdef$"

  create_table "logmnr_col$", id: false, force: :cascade do |t|
    t.integer "col#",         limit: 22, precision: 22
    t.integer "segcol#",      limit: 22, precision: 22
    t.string  "name",         limit: 30
    t.integer "type#",        limit: 22, precision: 22
    t.integer "length",       limit: 22, precision: 22
    t.integer "precision#",   limit: 22, precision: 22
    t.integer "scale",        limit: 22, precision: 22
    t.integer "null$",        limit: 22, precision: 22
    t.integer "intcol#",      limit: 22, precision: 22
    t.integer "property",     limit: 22, precision: 22
    t.integer "charsetid",    limit: 22, precision: 22
    t.integer "charsetform",  limit: 22, precision: 22
    t.integer "spare1",       limit: 22, precision: 22
    t.integer "spare2",       limit: 22, precision: 22
    t.integer "obj#",         limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_col$", ["logmnr_uid", "obj#", "col#"], name: "logmnr_i3col$"
  add_index "logmnr_col$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1col$"
  add_index "logmnr_col$", ["logmnr_uid", "obj#", "name"], name: "logmnr_i2col$"

  create_table "logmnr_coltype$", id: false, force: :cascade do |t|
    t.decimal "col#"
    t.decimal "intcol#"
    t.raw     "toid",         limit: 16
    t.decimal "version#"
    t.decimal "packed"
    t.decimal "intcols"
    t.raw     "intcol#s"
    t.decimal "flags"
    t.decimal "typidcol#"
    t.decimal "synobj#"
    t.decimal "obj#",                                   null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_coltype$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1coltype$"

  create_table "logmnr_dictionary$", primary_key: "logmnr_uid", force: :cascade do |t|
    t.string  "db_name",              limit: 9
    t.integer "db_id",                limit: nil
    t.string  "db_created",           limit: 20
    t.string  "db_dict_created",      limit: 20
    t.integer "db_dict_scn",          limit: 22,  precision: 22
    t.raw     "db_thread_map",        limit: 8
    t.integer "db_txn_scnbas",        limit: 22,  precision: 22
    t.integer "db_txn_scnwrp",        limit: 22,  precision: 22
    t.integer "db_resetlogs_change#", limit: 22,  precision: 22
    t.string  "db_resetlogs_time",    limit: 20
    t.string  "db_version_time",      limit: 20
    t.string  "db_redo_type_id",      limit: 8
    t.string  "db_redo_release",      limit: 60
    t.string  "db_character_set",     limit: 30
    t.string  "db_version",           limit: 64
    t.string  "db_status",            limit: 64
    t.string  "db_global_name",       limit: 128
    t.integer "db_dict_maxobjects",   limit: 22,  precision: 22
    t.integer "db_dict_objectcount",  limit: 22,  precision: 22, null: false
    t.integer "logmnr_flags",         limit: 22,  precision: 22
  end

  add_index "logmnr_dictionary$", ["logmnr_uid"], name: "logmnr_i1dictionary$"

  create_table "logmnr_dictstate$", primary_key: "logmnr_uid", force: :cascade do |t|
    t.decimal "start_scnbas"
    t.decimal "start_scnwrp"
    t.decimal "end_scnbas"
    t.decimal "end_scnwrp"
    t.decimal "redo_thread"
    t.decimal "rbasqn"
    t.decimal "rbablk"
    t.decimal "rbabyte"
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  create_table "logmnr_enc$", id: false, force: :cascade do |t|
    t.decimal "obj#"
    t.decimal "owner#"
    t.decimal "encalg"
    t.decimal "intalg"
    t.raw     "colklc"
    t.decimal "klclen"
    t.decimal "flag"
    t.string  "mkeyid",       limit: 64,                null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_enc$", ["logmnr_uid", "obj#", "owner#"], name: "logmnr_i1enc$"

  create_table "logmnr_error$", id: false, force: :cascade do |t|
    t.decimal  "session#"
    t.datetime "time_of_error"
    t.decimal  "code"
    t.string   "message",       limit: 4000
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.decimal  "spare3"
    t.string   "spare4",        limit: 4000
    t.string   "spare5",        limit: 4000
  end

  create_table "logmnr_filter$", id: false, force: :cascade do |t|
    t.decimal  "session#"
    t.string   "filter_type", limit: 30
    t.decimal  "attr1"
    t.decimal  "attr2"
    t.decimal  "attr3"
    t.decimal  "attr4"
    t.decimal  "attr5"
    t.decimal  "attr6"
    t.decimal  "filter_scn"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.datetime "spare3"
  end

  create_table "logmnr_global$", id: false, force: :cascade do |t|
    t.decimal  "high_recid_foreign"
    t.decimal  "high_recid_deleted"
    t.decimal  "local_reset_scn"
    t.decimal  "local_reset_timestamp"
    t.decimal  "version_timestamp"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.decimal  "spare3"
    t.string   "spare4",                limit: 2000
    t.datetime "spare5"
  end

  create_table "logmnr_gt_tab_include$", temporary: true, id: false, force: :cascade do |t|
    t.string "schema_name", limit: 32
    t.string "table_name",  limit: 32
  end

  create_table "logmnr_gt_user_include$", temporary: true, id: false, force: :cascade do |t|
    t.string  "user_name", limit: 32
    t.decimal "user_type"
  end

  create_table "logmnr_gt_xid_include$", temporary: true, id: false, force: :cascade do |t|
    t.decimal "xidusn"
    t.decimal "xidslt"
    t.decimal "xidsqn"
  end

  create_table "logmnr_icol$", id: false, force: :cascade do |t|
    t.decimal "obj#"
    t.decimal "bo#"
    t.decimal "col#"
    t.decimal "pos#"
    t.decimal "segcol#"
    t.decimal "intcol#",                                null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_icol$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1icol$"

  create_table "logmnr_ind$", id: false, force: :cascade do |t|
    t.integer "bo#",          limit: 22, precision: 22
    t.integer "cols",         limit: 22, precision: 22
    t.integer "type#",        limit: 22, precision: 22
    t.decimal "flags"
    t.decimal "property"
    t.integer "obj#",         limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_ind$", ["logmnr_uid", "bo#"], name: "logmnr_i2ind$"
  add_index "logmnr_ind$", ["logmnr_uid", "obj#"], name: "logmnr_i1ind$"

  create_table "logmnr_indcompart$", id: false, force: :cascade do |t|
    t.decimal "obj#"
    t.decimal "dataobj#"
    t.decimal "bo#"
    t.decimal "part#",                                  null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_indcompart$", ["logmnr_uid", "obj#"], name: "logmnr_i1indcompart$"

  create_table "logmnr_indpart$", id: false, force: :cascade do |t|
    t.decimal "obj#"
    t.decimal "bo#"
    t.decimal "part#"
    t.decimal "ts#",                                    null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_indpart$", ["logmnr_uid", "bo#"], name: "logmnr_i2indpart$"
  add_index "logmnr_indpart$", ["logmnr_uid", "obj#", "bo#"], name: "logmnr_i1indpart$"

  create_table "logmnr_indsubpart$", id: false, force: :cascade do |t|
    t.integer "obj#",         limit: 22, precision: 22
    t.integer "dataobj#",     limit: 22, precision: 22
    t.integer "pobj#",        limit: 22, precision: 22
    t.integer "subpart#",     limit: 22, precision: 22
    t.integer "ts#",          limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_indsubpart$", ["logmnr_uid", "obj#", "pobj#"], name: "logmnr_i1indsubpart$"

  create_table "logmnr_integrated_spill$", id: false, force: :cascade do |t|
    t.decimal  "session#",   null: false
    t.decimal  "xidusn",     null: false
    t.decimal  "xidslt",     null: false
    t.decimal  "xidsqn",     null: false
    t.decimal  "chunk",      null: false
    t.decimal  "flag",       null: false
    t.datetime "ctime"
    t.datetime "mtime"
    t.binary   "spill_data"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.decimal  "spare3"
    t.datetime "spare4"
    t.datetime "spare5"
  end

  create_table "logmnr_kopm$", id: false, force: :cascade do |t|
    t.decimal "length"
    t.raw     "metadata",     limit: 255
    t.string  "name",         limit: 30,                 null: false
    t.integer "logmnr_uid",   limit: 22,  precision: 22
    t.integer "logmnr_flags", limit: 22,  precision: 22
  end

  add_index "logmnr_kopm$", ["logmnr_uid", "name"], name: "logmnr_i1kopm$"

  create_table "logmnr_lob$", id: false, force: :cascade do |t|
    t.decimal "obj#"
    t.decimal "intcol#"
    t.decimal "col#"
    t.decimal "lobj#"
    t.decimal "chunk",                                  null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_lob$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1lob$"

  create_table "logmnr_lobfrag$", id: false, force: :cascade do |t|
    t.decimal "fragobj#"
    t.decimal "parentobj#"
    t.decimal "tabfragobj#"
    t.decimal "indfragobj#"
    t.decimal "frag#",                                  null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_lobfrag$", ["logmnr_uid", "fragobj#"], name: "logmnr_i1lobfrag$"

  create_table "logmnr_log$", id: false, force: :cascade do |t|
    t.decimal  "session#",                           null: false
    t.decimal  "thread#",                            null: false
    t.decimal  "sequence#",                          null: false
    t.decimal  "first_change#",                      null: false
    t.decimal  "next_change#"
    t.datetime "first_time"
    t.datetime "next_time"
    t.string   "file_name",              limit: 513
    t.decimal  "status"
    t.string   "info",                   limit: 32
    t.datetime "timestamp"
    t.string   "dict_begin",             limit: 3
    t.string   "dict_end",               limit: 3
    t.string   "status_info",            limit: 32
    t.integer  "db_id",                  limit: nil, null: false
    t.decimal  "resetlogs_change#",                  null: false
    t.decimal  "reset_timestamp",                    null: false
    t.decimal  "prev_resetlogs_change#"
    t.decimal  "prev_reset_timestamp"
    t.decimal  "blocks"
    t.decimal  "block_size"
    t.decimal  "flags"
    t.decimal  "contents"
    t.decimal  "recid"
    t.decimal  "recstamp"
    t.decimal  "mark_delete_timestamp"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.decimal  "spare3"
    t.decimal  "spare4"
    t.decimal  "spare5"
  end

  add_index "logmnr_log$", ["first_change#"], name: "logmnr_log$_first_change#", tablespace: "sysaux"
  add_index "logmnr_log$", ["flags"], name: "logmnr_log$_flags", tablespace: "sysaux"
  add_index "logmnr_log$", ["recid"], name: "logmnr_log$_recid", tablespace: "sysaux"

  create_table "logmnr_logmnr_buildlog", id: false, force: :cascade do |t|
    t.string  "build_date",              limit: 20
    t.decimal "db_txn_scnbas"
    t.decimal "db_txn_scnwrp"
    t.decimal "current_build_state"
    t.decimal "completion_status"
    t.decimal "marked_log_file_low_scn"
    t.string  "initial_xid",             limit: 22,                null: false
    t.integer "logmnr_uid",              limit: 22, precision: 22
    t.integer "logmnr_flags",            limit: 22, precision: 22
  end

  add_index "logmnr_logmnr_buildlog", ["logmnr_uid", "initial_xid"], name: "logmnr_i1logmnr_buildlog"

  create_table "logmnr_ntab$", id: false, force: :cascade do |t|
    t.decimal "col#"
    t.decimal "intcol#"
    t.decimal "ntab#"
    t.string  "name",         limit: 4000
    t.decimal "obj#",                                     null: false
    t.integer "logmnr_uid",   limit: 22,   precision: 22
    t.integer "logmnr_flags", limit: 22,   precision: 22
  end

  add_index "logmnr_ntab$", ["logmnr_uid", "ntab#"], name: "logmnr_i2ntab$"
  add_index "logmnr_ntab$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1ntab$"

  create_table "logmnr_obj$", id: false, force: :cascade do |t|
    t.integer  "objv#",        limit: 22,  precision: 22
    t.integer  "owner#",       limit: 22,  precision: 22
    t.string   "name",         limit: 30
    t.integer  "namespace",    limit: 22,  precision: 22
    t.string   "subname",      limit: 30
    t.integer  "type#",        limit: 22,  precision: 22
    t.raw      "oid$",         limit: 16
    t.string   "remoteowner",  limit: 30
    t.string   "linkname",     limit: 128
    t.integer  "flags",        limit: 22,  precision: 22
    t.integer  "spare3",       limit: 22,  precision: 22
    t.datetime "stime"
    t.integer  "obj#",         limit: 22,  precision: 22, null: false
    t.integer  "logmnr_uid",   limit: 22,  precision: 22
    t.integer  "logmnr_flags", limit: 22,  precision: 22
    t.decimal  "start_scnbas"
    t.decimal  "start_scnwrp"
  end

  add_index "logmnr_obj$", ["logmnr_uid", "obj#"], name: "logmnr_i1obj$"
  add_index "logmnr_obj$", ["logmnr_uid", "oid$"], name: "logmnr_i2obj$"

  create_table "logmnr_opqtype$", id: false, force: :cascade do |t|
    t.decimal "intcol#",                                  null: false
    t.decimal "type"
    t.decimal "flags"
    t.decimal "lobcol"
    t.decimal "objcol"
    t.decimal "extracol"
    t.raw     "schemaoid",    limit: 16
    t.decimal "elemnum"
    t.string  "schemaurl",    limit: 4000
    t.decimal "obj#",                                     null: false
    t.integer "logmnr_uid",   limit: 22,   precision: 22
    t.integer "logmnr_flags", limit: 22,   precision: 22
  end

  add_index "logmnr_opqtype$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1opqtype$"

  create_table "logmnr_parameter$", id: false, force: :cascade do |t|
    t.decimal "session#",              null: false
    t.string  "name",     limit: 30,   null: false
    t.string  "value",    limit: 2000
    t.decimal "type"
    t.decimal "scn"
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3",   limit: 2000
  end

  add_index "logmnr_parameter$", ["session#", "name"], name: "logmnr_parameter_indx"

  create_table "logmnr_partobj$", id: false, force: :cascade do |t|
    t.decimal "parttype"
    t.decimal "partcnt"
    t.decimal "partkeycols"
    t.decimal "flags"
    t.decimal "defts#"
    t.decimal "defpctfree"
    t.decimal "defpctused"
    t.decimal "defpctthres"
    t.decimal "definitrans"
    t.decimal "defmaxtrans"
    t.decimal "deftiniexts"
    t.decimal "defextsize"
    t.decimal "defminexts"
    t.decimal "defmaxexts"
    t.decimal "defextpct"
    t.decimal "deflists"
    t.decimal "defgroups"
    t.decimal "deflogging"
    t.decimal "spare1"
    t.decimal "spare2"
    t.decimal "spare3"
    t.decimal "definclcol"
    t.string  "parameters",   limit: 1000
    t.decimal "obj#",                                     null: false
    t.integer "logmnr_uid",   limit: 22,   precision: 22
    t.integer "logmnr_flags", limit: 22,   precision: 22
  end

  add_index "logmnr_partobj$", ["logmnr_uid", "obj#"], name: "logmnr_i1partobj$"

  create_table "logmnr_processed_log$", id: false, force: :cascade do |t|
    t.decimal  "session#",                  null: false
    t.decimal  "thread#",                   null: false
    t.decimal  "sequence#"
    t.decimal  "first_change#"
    t.decimal  "next_change#"
    t.datetime "first_time"
    t.datetime "next_time"
    t.string   "file_name",     limit: 513
    t.decimal  "status"
    t.string   "info",          limit: 32
    t.datetime "timestamp"
  end

  create_table "logmnr_props$", id: false, force: :cascade do |t|
    t.string  "value$",       limit: 4000
    t.string  "comment$",     limit: 4000
    t.string  "name",         limit: 30,                  null: false
    t.integer "logmnr_uid",   limit: 22,   precision: 22
    t.integer "logmnr_flags", limit: 22,   precision: 22
  end

  add_index "logmnr_props$", ["logmnr_uid", "name"], name: "logmnr_i1props$"

  create_table "logmnr_refcon$", id: false, force: :cascade do |t|
    t.decimal "col#"
    t.decimal "intcol#"
    t.decimal "reftyp"
    t.raw     "stabid",       limit: 16
    t.raw     "expctoid",     limit: 16
    t.decimal "obj#",                                   null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_refcon$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1refcon$"

  create_table "logmnr_restart_ckpt$", id: false, force: :cascade do |t|
    t.decimal "session#",    null: false
    t.decimal "valid"
    t.decimal "ckpt_scn",    null: false
    t.decimal "xidusn",      null: false
    t.decimal "xidslt",      null: false
    t.decimal "xidsqn",      null: false
    t.decimal "session_num", null: false
    t.decimal "serial_num",  null: false
    t.binary  "ckpt_info"
    t.decimal "flag"
    t.decimal "offset"
    t.binary  "client_data"
    t.decimal "spare1"
    t.decimal "spare2"
  end

  create_table "logmnr_restart_ckpt_txinfo$", id: false, force: :cascade do |t|
    t.decimal "session#",      null: false
    t.decimal "xidusn",        null: false
    t.decimal "xidslt",        null: false
    t.decimal "xidsqn",        null: false
    t.decimal "session_num",   null: false
    t.decimal "serial_num",    null: false
    t.decimal "flag"
    t.decimal "start_scn"
    t.decimal "effective_scn", null: false
    t.decimal "offset"
    t.binary  "tx_data"
  end

  create_table "logmnr_seed$", id: false, force: :cascade do |t|
    t.integer "seed_version",   limit: 22, precision: 22
    t.integer "gather_version", limit: 22, precision: 22
    t.string  "schemaname",     limit: 30
    t.decimal "obj#"
    t.integer "objv#",          limit: 22, precision: 22
    t.string  "table_name",     limit: 30
    t.string  "col_name",       limit: 30
    t.decimal "col#"
    t.decimal "intcol#"
    t.decimal "segcol#"
    t.decimal "type#"
    t.decimal "length"
    t.decimal "precision#"
    t.decimal "scale"
    t.decimal "null$",                                    null: false
    t.integer "logmnr_uid",     limit: 22, precision: 22
    t.integer "logmnr_flags",   limit: 22, precision: 22
  end

  add_index "logmnr_seed$", ["logmnr_uid", "obj#", "intcol#"], name: "logmnr_i1seed$"
  add_index "logmnr_seed$", ["logmnr_uid", "schemaname", "table_name", "col_name", "obj#", "intcol#"], name: "logmnr_i2seed$"

  create_table "logmnr_session$", primary_key: "session#", force: :cascade do |t|
    t.decimal  "client#"
    t.string   "session_name",         limit: 128,  null: false
    t.integer  "db_id",                limit: nil
    t.decimal  "resetlogs_change#"
    t.decimal  "session_attr"
    t.string   "session_attr_verbose", limit: 400
    t.decimal  "start_scn"
    t.decimal  "end_scn"
    t.decimal  "spill_scn"
    t.datetime "spill_time"
    t.decimal  "oldest_scn"
    t.decimal  "resume_scn"
    t.string   "global_db_name",       limit: 128
    t.decimal  "reset_timestamp"
    t.decimal  "branch_scn"
    t.string   "version",              limit: 64
    t.string   "redo_compat",          limit: 20
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.decimal  "spare3"
    t.decimal  "spare4"
    t.decimal  "spare5"
    t.datetime "spare6"
    t.string   "spare7",               limit: 1000
    t.string   "spare8",               limit: 1000
  end

  add_index "logmnr_session$", ["session_name"], name: "logmnr_session_uk1", unique: true

  create_table "logmnr_session_actions$", id: false, force: :cascade do |t|
    t.decimal   "flagsruntime",                 default: 0.0
    t.decimal   "dropscn"
    t.timestamp "modifytime",      limit: 6
    t.timestamp "dispatchtime",    limit: 6
    t.timestamp "droptime",        limit: 6
    t.decimal   "lcrcount",                     default: 0.0
    t.string    "actionname",      limit: 30,                 null: false
    t.decimal   "logmnrsession#",                             null: false
    t.decimal   "processrole#",                               null: false
    t.decimal   "actiontype#",                                null: false
    t.decimal   "flagsdefinetime"
    t.timestamp "createtime",      limit: 6
    t.decimal   "xidusn"
    t.decimal   "xidslt"
    t.decimal   "xidsqn"
    t.decimal   "thread#"
    t.decimal   "startscn"
    t.decimal   "startsubscn"
    t.decimal   "endscn"
    t.decimal   "endsubscn"
    t.decimal   "rbasqn"
    t.decimal   "rbablk"
    t.decimal   "rbabyte"
    t.decimal   "session#"
    t.decimal   "obj#"
    t.decimal   "attr1"
    t.decimal   "attr2"
    t.decimal   "attr3"
    t.decimal   "spare1"
    t.decimal   "spare2"
    t.timestamp "spare3",          limit: 6
    t.string    "spare4",          limit: 2000
  end

  create_table "logmnr_session_evolve$", id: false, force: :cascade do |t|
    t.decimal  "branch_level"
    t.decimal  "session#",                         null: false
    t.integer  "db_id",                limit: nil, null: false
    t.decimal  "reset_scn",                        null: false
    t.decimal  "reset_timestamp",                  null: false
    t.decimal  "prev_reset_scn"
    t.decimal  "prev_reset_timestamp"
    t.decimal  "status"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.decimal  "spare3"
    t.datetime "spare4"
  end

  create_table "logmnr_spill$", id: false, force: :cascade do |t|
    t.decimal "session#",   null: false
    t.decimal "xidusn",     null: false
    t.decimal "xidslt",     null: false
    t.decimal "xidsqn",     null: false
    t.decimal "chunk",      null: false
    t.decimal "startidx",   null: false
    t.decimal "endidx",     null: false
    t.decimal "flag",       null: false
    t.decimal "sequence#",  null: false
    t.binary  "spill_data"
    t.decimal "spare1"
    t.decimal "spare2"
  end

  create_table "logmnr_subcoltype$", id: false, force: :cascade do |t|
    t.decimal "intcol#",                                null: false
    t.raw     "toid",         limit: 16,                null: false
    t.decimal "version#",                               null: false
    t.decimal "intcols"
    t.raw     "intcol#s"
    t.decimal "flags"
    t.decimal "synobj#"
    t.decimal "obj#",                                   null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_subcoltype$", ["logmnr_uid", "obj#", "intcol#", "toid"], name: "logmnr_i1subcoltype$"

  create_table "logmnr_tab$", id: false, force: :cascade do |t|
    t.integer "ts#",          limit: 22, precision: 22
    t.integer "cols",         limit: 22, precision: 22
    t.integer "property",     limit: 22, precision: 22
    t.integer "intcols",      limit: 22, precision: 22
    t.integer "kernelcols",   limit: 22, precision: 22
    t.integer "bobj#",        limit: 22, precision: 22
    t.integer "trigflag",     limit: 22, precision: 22
    t.integer "flags",        limit: 22, precision: 22
    t.integer "obj#",         limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_tab$", ["logmnr_uid", "bobj#"], name: "logmnr_i2tab$"
  add_index "logmnr_tab$", ["logmnr_uid", "obj#"], name: "logmnr_i1tab$"

  create_table "logmnr_tabcompart$", id: false, force: :cascade do |t|
    t.integer "obj#",         limit: 22, precision: 22
    t.integer "bo#",          limit: 22, precision: 22
    t.integer "part#",        limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_tabcompart$", ["logmnr_uid", "bo#"], name: "logmnr_i2tabcompart$"
  add_index "logmnr_tabcompart$", ["logmnr_uid", "obj#"], name: "logmnr_i1tabcompart$"

  create_table "logmnr_tabpart$", id: false, force: :cascade do |t|
    t.integer "obj#",         limit: 22, precision: 22
    t.integer "ts#",          limit: 22, precision: 22
    t.decimal "part#"
    t.integer "bo#",          limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_tabpart$", ["logmnr_uid", "bo#"], name: "logmnr_i2tabpart$"
  add_index "logmnr_tabpart$", ["logmnr_uid", "obj#", "bo#"], name: "logmnr_i1tabpart$"

  create_table "logmnr_tabsubpart$", id: false, force: :cascade do |t|
    t.integer "obj#",         limit: 22, precision: 22
    t.integer "dataobj#",     limit: 22, precision: 22
    t.integer "pobj#",        limit: 22, precision: 22
    t.integer "subpart#",     limit: 22, precision: 22
    t.integer "ts#",          limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_tabsubpart$", ["logmnr_uid", "obj#", "pobj#"], name: "logmnr_i1tabsubpart$"
  add_index "logmnr_tabsubpart$", ["logmnr_uid", "pobj#"], name: "logmnr_i2tabsubpart$"

  create_table "logmnr_ts$", id: false, force: :cascade do |t|
    t.integer "ts#",          limit: 22, precision: 22
    t.string  "name",         limit: 30
    t.integer "owner#",       limit: 22, precision: 22
    t.integer "blocksize",    limit: 22, precision: 22, null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_ts$", ["logmnr_uid", "ts#"], name: "logmnr_i1ts$"

  create_table "logmnr_type$", id: false, force: :cascade do |t|
    t.decimal "version#"
    t.string  "version",         limit: 30
    t.raw     "tvoid",           limit: 16
    t.decimal "typecode"
    t.decimal "properties"
    t.decimal "attributes"
    t.decimal "methods"
    t.decimal "hiddenmethods"
    t.decimal "supertypes"
    t.decimal "subtypes"
    t.decimal "externtype"
    t.string  "externname",      limit: 4000
    t.string  "helperclassname", limit: 4000
    t.decimal "local_attrs"
    t.decimal "local_methods"
    t.raw     "typeid",          limit: 16
    t.raw     "roottoid",        limit: 16
    t.decimal "spare1"
    t.decimal "spare2"
    t.decimal "spare3"
    t.raw     "supertoid",       limit: 16
    t.raw     "hashcode",        limit: 17
    t.raw     "toid",            limit: 16,                  null: false
    t.integer "logmnr_uid",      limit: 22,   precision: 22
    t.integer "logmnr_flags",    limit: 22,   precision: 22
  end

  add_index "logmnr_type$", ["logmnr_uid", "toid", "version#"], name: "logmnr_i1type$"

  create_table "logmnr_uid$", primary_key: "session#", force: :cascade do |t|
    t.integer "logmnr_uid", limit: 22, precision: 22
  end

  create_table "logmnr_user$", id: false, force: :cascade do |t|
    t.integer "user#",        limit: 22, precision: 22
    t.string  "name",         limit: 30,                null: false
    t.integer "logmnr_uid",   limit: 22, precision: 22
    t.integer "logmnr_flags", limit: 22, precision: 22
  end

  add_index "logmnr_user$", ["logmnr_uid", "user#"], name: "logmnr_i1user$"

  create_table "logmnrc_dbname_uid_map", primary_key: "global_name", force: :cascade do |t|
    t.decimal "logmnr_uid"
    t.decimal "flags"
  end

  create_table "logmnrc_gsba", id: false, force: :cascade do |t|
    t.decimal  "logmnr_uid",                    null: false
    t.decimal  "as_of_scn",                     null: false
    t.decimal  "fdo_length"
    t.raw      "fdo_value",        limit: 255
    t.decimal  "charsetid"
    t.decimal  "ncharsetid"
    t.decimal  "dbtimezone_len"
    t.string   "dbtimezone_value", limit: 64
    t.decimal  "logmnr_spare1"
    t.decimal  "logmnr_spare2"
    t.string   "logmnr_spare3",    limit: 1000
    t.datetime "logmnr_spare4"
  end

  create_table "logmnrc_gsii", id: false, force: :cascade do |t|
    t.decimal  "logmnr_uid",                 null: false
    t.decimal  "obj#",                       null: false
    t.decimal  "bo#",                        null: false
    t.decimal  "indtype#",                   null: false
    t.decimal  "drop_scn"
    t.decimal  "logmnr_spare1"
    t.decimal  "logmnr_spare2"
    t.string   "logmnr_spare3", limit: 1000
    t.datetime "logmnr_spare4"
  end

  create_table "logmnrc_gtcs", id: false, force: :cascade do |t|
    t.decimal  "logmnr_uid",                               null: false
    t.decimal  "obj#",                                     null: false
    t.decimal  "objv#",                                    null: false
    t.decimal  "segcol#",                                  null: false
    t.decimal  "intcol#",                                  null: false
    t.string   "colname",                     limit: 30,   null: false
    t.decimal  "type#",                                    null: false
    t.decimal  "length"
    t.decimal  "precision"
    t.decimal  "scale"
    t.decimal  "interval_leading_precision"
    t.decimal  "interval_trailing_precision"
    t.decimal  "property"
    t.raw      "toid",                        limit: 16
    t.decimal  "charsetid"
    t.decimal  "charsetform"
    t.string   "typename",                    limit: 30
    t.string   "fqcolname",                   limit: 4000
    t.decimal  "numintcols"
    t.decimal  "numattrs"
    t.decimal  "adtorder"
    t.decimal  "logmnr_spare1"
    t.decimal  "logmnr_spare2"
    t.string   "logmnr_spare3",               limit: 1000
    t.datetime "logmnr_spare4"
    t.decimal  "logmnr_spare5"
    t.decimal  "logmnr_spare6"
    t.decimal  "logmnr_spare7"
    t.decimal  "logmnr_spare8"
    t.decimal  "logmnr_spare9"
    t.decimal  "col#"
    t.string   "xtypeschemaname",             limit: 30
    t.string   "xtypename",                   limit: 4000
    t.string   "xfqcolname",                  limit: 4000
    t.decimal  "xtopintcol"
    t.decimal  "xreffedtableobjn"
    t.decimal  "xreffedtableobjv"
    t.decimal  "xcoltypeflags"
    t.decimal  "xopqtypetype"
    t.decimal  "xopqtypeflags"
    t.decimal  "xopqlobintcol"
    t.decimal  "xopqobjintcol"
    t.decimal  "xxmlintcol"
    t.decimal  "eaowner#"
    t.string   "eamkeyid",                    limit: 64
    t.decimal  "eaencalg"
    t.decimal  "eaintalg"
    t.raw      "eacolklc"
    t.decimal  "eaklclen"
    t.decimal  "eaflags"
  end

  add_index "logmnrc_gtcs", ["logmnr_uid", "obj#", "objv#", "segcol#", "intcol#"], name: "logmnrc_i2gtcs"

  create_table "logmnrc_gtlo", id: false, force: :cascade do |t|
    t.decimal  "logmnr_uid",                      null: false
    t.decimal  "keyobj#",                         null: false
    t.decimal  "lvlcnt",                          null: false
    t.decimal  "baseobj#",                        null: false
    t.decimal  "baseobjv#",                       null: false
    t.decimal  "lvl1obj#"
    t.decimal  "lvl2obj#"
    t.decimal  "lvl0type#",                       null: false
    t.decimal  "lvl1type#"
    t.decimal  "lvl2type#"
    t.decimal  "owner#"
    t.string   "ownername",          limit: 30,   null: false
    t.string   "lvl0name",           limit: 30,   null: false
    t.string   "lvl1name",           limit: 30
    t.string   "lvl2name",           limit: 30
    t.decimal  "intcols",                         null: false
    t.decimal  "cols"
    t.decimal  "kernelcols"
    t.decimal  "tab_flags"
    t.decimal  "trigflag"
    t.decimal  "assoc#"
    t.decimal  "obj_flags"
    t.decimal  "ts#"
    t.string   "tsname",             limit: 30
    t.decimal  "property"
    t.decimal  "start_scn",                       null: false
    t.decimal  "drop_scn"
    t.decimal  "xidusn"
    t.decimal  "xidslt"
    t.decimal  "xidsqn"
    t.decimal  "flags"
    t.decimal  "logmnr_spare1"
    t.decimal  "logmnr_spare2"
    t.string   "logmnr_spare3",      limit: 1000
    t.datetime "logmnr_spare4"
    t.decimal  "logmnr_spare5"
    t.decimal  "logmnr_spare6"
    t.decimal  "logmnr_spare7"
    t.decimal  "logmnr_spare8"
    t.decimal  "logmnr_spare9"
    t.decimal  "parttype"
    t.decimal  "subparttype"
    t.decimal  "unsupportedcols"
    t.decimal  "complextypecols"
    t.decimal  "ntparentobjnum"
    t.decimal  "ntparentobjversion"
    t.decimal  "ntparentintcolnum"
    t.decimal  "logmnrtloflags"
    t.string   "logmnrmcv",          limit: 30
  end

  add_index "logmnrc_gtlo", ["logmnr_uid", "baseobj#", "baseobjv#"], name: "logmnrc_i2gtlo"
  add_index "logmnrc_gtlo", ["logmnr_uid", "drop_scn"], name: "logmnrc_i3gtlo"

  create_table "logmnrp_ctas_part_map", id: false, force: :cascade do |t|
    t.decimal "logmnr_uid",              null: false
    t.decimal "baseobj#",                null: false
    t.decimal "baseobjv#",               null: false
    t.decimal "keyobj#",                 null: false
    t.decimal "part#",                   null: false
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3",     limit: 1000
  end

  add_index "logmnrp_ctas_part_map", ["logmnr_uid", "baseobj#", "baseobjv#", "part#"], name: "logmnrp_ctas_part_map_i"

# Could not dump table "logmnrt_mddl$" because of following StandardError
#   Unknown type 'ROWID' for column 'source_rowid'

  create_table "logstdby$apply_milestone", id: false, force: :cascade do |t|
    t.integer  "session_id",     limit: nil,                null: false
    t.decimal  "commit_scn",                                null: false
    t.datetime "commit_time"
    t.decimal  "synch_scn",                                 null: false
    t.decimal  "epoch",                                     null: false
    t.decimal  "processed_scn",                             null: false
    t.datetime "processed_time"
    t.decimal  "fetchlwm_scn",                default: 0.0, null: false
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.string   "spare3",         limit: 2000
  end

  create_table "logstdby$apply_progress", id: false, force: :cascade do |t|
    t.decimal  "xidusn"
    t.decimal  "xidslt"
    t.decimal  "xidsqn"
    t.decimal  "commit_scn"
    t.datetime "commit_time"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.string   "spare3",      limit: 2000
  end

  create_table "logstdby$eds_tables", id: false, force: :cascade do |t|
    t.string    "owner",               limit: 30, null: false
    t.string    "table_name",          limit: 30, null: false
    t.string    "shadow_table_name",   limit: 30
    t.string    "base_trigger_name",   limit: 30
    t.string    "shadow_trigger_name", limit: 30
    t.string    "dblink"
    t.decimal   "flags"
    t.string    "state"
    t.decimal   "objv"
    t.decimal   "obj#"
    t.decimal   "sobj#"
    t.timestamp "ctime",               limit: 6
    t.decimal   "spare1"
    t.string    "spare2"
    t.decimal   "spare3"
  end

  create_table "logstdby$events", id: false, force: :cascade do |t|
    t.timestamp "event_time",  limit: 6,    null: false
    t.decimal   "current_scn"
    t.decimal   "commit_scn"
    t.decimal   "xidusn"
    t.decimal   "xidslt"
    t.decimal   "xidsqn"
    t.decimal   "errval"
    t.string    "event",       limit: 2000
    t.text      "full_event"
    t.string    "error",       limit: 2000
    t.decimal   "spare1"
    t.decimal   "spare2"
    t.string    "spare3",      limit: 2000
  end

  add_index "logstdby$events", ["commit_scn"], name: "logstdby$events_ind_scn", tablespace: "sysaux"
  add_index "logstdby$events", ["event_time"], name: "logstdby$events_ind", tablespace: "sysaux"
  add_index "logstdby$events", ["xidusn", "xidslt", "xidsqn"], name: "logstdby$events_ind_xid", tablespace: "sysaux"

  create_table "logstdby$flashback_scn", primary_key: "primary_scn", force: :cascade do |t|
    t.datetime "primary_time"
    t.decimal  "standby_scn"
    t.datetime "standby_time"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.datetime "spare3"
  end

  create_table "logstdby$history", id: false, force: :cascade do |t|
    t.decimal  "stream_sequence#"
    t.decimal  "lmnr_sid"
    t.decimal  "dbid"
    t.decimal  "first_change#"
    t.decimal  "last_change#"
    t.decimal  "source"
    t.decimal  "status"
    t.datetime "first_time"
    t.datetime "last_time"
    t.string   "dgname"
    t.decimal  "spare1"
    t.decimal  "spare2"
    t.string   "spare3",           limit: 2000
  end

  create_table "logstdby$parameters", id: false, force: :cascade do |t|
    t.string  "name",   limit: 30
    t.string  "value",  limit: 2000
    t.decimal "type"
    t.decimal "scn"
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3", limit: 2000
  end

  create_table "logstdby$plsql", id: false, force: :cascade do |t|
    t.integer "session_id",   limit: nil
    t.decimal "start_finish"
    t.text    "call_text"
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3",       limit: 2000
  end

  create_table "logstdby$scn", id: false, force: :cascade do |t|
    t.decimal "obj#"
    t.string  "objname", limit: 4000
    t.string  "schema",  limit: 30
    t.string  "type",    limit: 20
    t.decimal "scn"
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3",  limit: 2000
  end

  create_table "logstdby$skip", id: false, force: :cascade do |t|
    t.decimal "error"
    t.string  "statement_opt", limit: 30
    t.string  "schema",        limit: 30
    t.string  "name",          limit: 65
    t.decimal "use_like"
    t.boolean "esc",           limit: nil
    t.string  "proc",          limit: 98
    t.decimal "active"
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3",        limit: 2000
  end

  add_index "logstdby$skip", ["statement_opt"], name: "logstdby$skip_idx2", tablespace: "sysaux"
  add_index "logstdby$skip", ["use_like", "schema", "name"], name: "logstdby$skip_idx1", tablespace: "sysaux"

  create_table "logstdby$skip_support", id: false, force: :cascade do |t|
    t.decimal "action",                             null: false
    t.string  "name",   limit: 30,                  null: false
    t.integer "reg",                 precision: 38
    t.decimal "spare1"
    t.decimal "spare2"
    t.string  "spare3", limit: 2000
  end

  add_index "logstdby$skip_support", ["name", "action"], name: "logstdby$skip_ind", unique: true, tablespace: "sysaux"

  create_table "logstdby$skip_transaction", id: false, force: :cascade do |t|
    t.decimal "xidusn"
    t.decimal "xidslt"
    t.decimal "xidsqn"
    t.decimal "active"
    t.decimal "commit_scn"
    t.decimal "spare2"
    t.string  "spare3",     limit: 2000
  end

  create_table "mview$_adv_ajg", comment: "Anchor-join graph representation", primary_key: "ajgid#", force: :cascade do |t|
    t.decimal "runid#",                null: false
    t.decimal "ajgdeslen",             null: false
    t.raw     "ajgdes",    limit: nil, null: false
    t.decimal "hashvalue",             null: false
    t.decimal "frequency"
  end

  create_table "mview$_adv_basetable", comment: "Base tables refered by a query", id: false, force: :cascade do |t|
    t.decimal "collectionid#",            null: false
    t.decimal "queryid#",                 null: false
    t.string  "owner",         limit: 30
    t.string  "table_name",    limit: 30
    t.decimal "table_type"
  end

  add_index "mview$_adv_basetable", ["queryid#"], name: "mview$_adv_basetable_idx_01"

  create_table "mview$_adv_clique", comment: "Table for storing canonical form of Clique queries", primary_key: "cliqueid#", force: :cascade do |t|
    t.decimal "runid#",                   null: false
    t.decimal "cliquedeslen",             null: false
    t.raw     "cliquedes",    limit: nil, null: false
    t.decimal "hashvalue",                null: false
    t.decimal "frequency",                null: false
    t.decimal "bytecost",                 null: false
    t.decimal "rowsize",                  null: false
    t.decimal "numrows",                  null: false
  end

  create_table "mview$_adv_eligible", comment: "Summary management rewrite eligibility information", id: false, force: :cascade do |t|
    t.decimal "sumobjn#",  null: false
    t.decimal "runid#",    null: false
    t.decimal "bytecost",  null: false
    t.decimal "flags",     null: false
    t.decimal "frequency", null: false
  end

# Could not dump table "mview$_adv_exceptions" because of following StandardError
#   Unknown type 'ROWID' for column 'bad_rowid'

  create_table "mview$_adv_filter", comment: "Table for workload filter definition", id: false, force: :cascade do |t|
    t.decimal "filterid#",                  null: false
    t.decimal "subfilternum#",              null: false
    t.decimal "subfiltertype",              null: false
    t.string  "str_value",     limit: 1028
    t.decimal "num_value1"
    t.decimal "num_value2"
    t.date    "date_value1"
    t.date    "date_value2"
  end

  create_table "mview$_adv_filterinstance", comment: "Table for workload filter instance definition", id: false, force: :cascade do |t|
    t.decimal "runid#",                     null: false
    t.decimal "filterid#"
    t.decimal "subfilternum#"
    t.decimal "subfiltertype"
    t.string  "str_value",     limit: 1028
    t.decimal "num_value1"
    t.decimal "num_value2"
    t.date    "date_value1"
    t.date    "date_value2"
  end

  create_table "mview$_adv_fjg", comment: "Representation for query join sub-graph not in AJG ", primary_key: "fjgid#", force: :cascade do |t|
    t.decimal "ajgid#",                null: false
    t.decimal "fjgdeslen",             null: false
    t.raw     "fjgdes",    limit: nil, null: false
    t.decimal "hashvalue",             null: false
    t.decimal "frequency"
  end

  create_table "mview$_adv_gc", comment: "Group-by columns of a query", primary_key: "gcid#", force: :cascade do |t|
    t.decimal "fjgid#",                null: false
    t.decimal "gcdeslen",              null: false
    t.raw     "gcdes",     limit: nil, null: false
    t.decimal "hashvalue",             null: false
    t.decimal "frequency"
  end

  create_table "mview$_adv_info", comment: "Internal table for passing information from the SQL analyzer", id: false, force: :cascade do |t|
    t.decimal "runid#",              null: false
    t.decimal "seq#",                null: false
    t.decimal "type",                null: false
    t.decimal "infolen",             null: false
    t.raw     "info",    limit: nil
    t.decimal "status"
    t.decimal "flag"
  end

# Could not dump table "mview$_adv_journal" because of following StandardError
#   Unknown type 'LONG' for column 'text'

  create_table "mview$_adv_level", comment: "Level definition", id: false, force: :cascade do |t|
    t.decimal "runid#",                null: false
    t.decimal "levelid#",              null: false
    t.decimal "dimobj#"
    t.decimal "flags",                 null: false
    t.decimal "tblobj#",               null: false
    t.raw     "columnlist", limit: 70, null: false
    t.string  "levelname",  limit: 30
  end

  create_table "mview$_adv_log", comment: "Log all calls to summary advisory functions", primary_key: "runid#", force: :cascade do |t|
    t.decimal  "filterid#"
    t.datetime "run_begin"
    t.datetime "run_end"
    t.decimal  "run_type"
    t.string   "uname",      limit: 30
    t.decimal  "status",                  null: false
    t.string   "message",    limit: 2000
    t.decimal  "completed"
    t.decimal  "total"
    t.string   "error_code", limit: 20
  end

# Could not dump table "mview$_adv_output" because of following StandardError
#   Unknown type 'LONG' for column 'query_text'

  create_table "mview$_adv_parameters", comment: "Summary advisor tuning parameters", primary_key: "parameter_name", force: :cascade do |t|
    t.decimal "parameter_type",             null: false
    t.string  "string_value",    limit: 30
    t.date    "date_value"
    t.decimal "numerical_value"
  end

# Could not dump table "mview$_adv_plan" because of following StandardError
#   Unknown type 'LONG' for column 'other'

# Could not dump table "mview$_adv_pretty" because of following StandardError
#   Unknown type 'LONG' for column 'sql_text'

  create_table "mview$_adv_rollup", comment: "Each row repesents either a functional dependency or join-key relationship", id: false, force: :cascade do |t|
    t.decimal "runid#",    null: false
    t.decimal "clevelid#", null: false
    t.decimal "plevelid#", null: false
    t.decimal "flags",     null: false
  end

  create_table "mview$_adv_sqldepend", comment: "Temporary table for workload collections", id: false, force: :cascade do |t|
    t.decimal "collectionid#"
    t.integer "inst_id",       limit: nil
    t.raw     "from_address",  limit: 16
    t.decimal "from_hash"
    t.string  "to_owner",      limit: 64
    t.string  "to_name",       limit: 1000
    t.decimal "to_type"
    t.decimal "cardinality"
  end

  add_index "mview$_adv_sqldepend", ["collectionid#", "from_address", "from_hash", "inst_id"], name: "mview$_adv_sqldepend_idx_01"

# Could not dump table "mview$_adv_temp" because of following StandardError
#   Unknown type 'LONG' for column 'text'

# Could not dump table "mview$_adv_workload" because of following StandardError
#   Unknown type 'LONG' for column 'sql_text'

  create_table "notification_relations", force: :cascade do |t|
    t.integer  "notification_id", limit: nil
    t.integer  "model_id",        limit: nil
    t.string   "model_type"
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "notification_relations", ["model_type", "model_id"], name: "i_not_rel_mod_typ_mod_id"
  add_index "notification_relations", ["notification_id"], name: "i_not_rel_not_id"

  create_table "notifications", force: :cascade do |t|
    t.integer  "status",                          precision: 38
    t.string   "confirmation_hash"
    t.text     "notes"
    t.date     "confirmation_date"
    t.integer  "user_id",             limit: nil
    t.integer  "user_who_confirm_id", limit: nil
    t.integer  "lock_version",                    precision: 38, default: 0
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
  end

  add_index "notifications", ["confirmation_hash"], name: "i_not_con_has", unique: true
  add_index "notifications", ["status"], name: "index_notifications_on_status"
  add_index "notifications", ["user_id"], name: "index_notifications_on_user_id"
  add_index "notifications", ["user_who_confirm_id"], name: "i_not_use_who_con_id"

# Could not dump table "ol$" because of following StandardError
#   Unknown type 'LONG' for column 'sql_text'

  create_table "ol$hints", temporary: true, id: false, force: :cascade do |t|
    t.string  "ol_name",         limit: 30
    t.decimal "hint#"
    t.string  "category",        limit: 30
    t.decimal "hint_type"
    t.string  "hint_text",       limit: 512
    t.decimal "stage#"
    t.decimal "node#"
    t.string  "table_name",      limit: 30
    t.decimal "table_tin"
    t.decimal "table_pos"
    t.integer "ref_id",          limit: nil
    t.string  "user_table_name", limit: 64
    t.float   "cost",            limit: 126
    t.float   "cardinality",     limit: 126
    t.float   "bytes",           limit: 126
    t.decimal "hint_textoff"
    t.decimal "hint_textlen"
    t.string  "join_pred",       limit: 2000
    t.decimal "spare1"
    t.decimal "spare2"
    t.text    "hint_string"
  end

  add_index "ol$hints", ["ol_name", "hint#"], name: "ol$hnt_num", unique: true

  create_table "ol$nodes", temporary: true, id: false, force: :cascade do |t|
    t.string  "ol_name",      limit: 30
    t.string  "category",     limit: 30
    t.integer "node_id",      limit: nil
    t.integer "parent_id",    limit: nil
    t.decimal "node_type"
    t.decimal "node_textlen"
    t.decimal "node_textoff"
    t.string  "node_name",    limit: 64
  end

  create_table "old_passwords", force: :cascade do |t|
    t.string   "password"
    t.integer  "user_id",    limit: nil
    t.datetime "created_at",             null: false
    t.datetime "updated_at",             null: false
  end

  add_index "old_passwords", ["created_at"], name: "i_old_passwords_created_at"
  add_index "old_passwords", ["user_id"], name: "index_old_passwords_on_user_id"

  create_table "organization_roles", force: :cascade do |t|
    t.integer  "user_id",         limit: nil
    t.integer  "organization_id", limit: nil
    t.integer  "role_id",         limit: nil
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "organization_roles", ["organization_id"], name: "i_org_rol_org_id"
  add_index "organization_roles", ["role_id"], name: "i_organization_roles_role_id"
  add_index "organization_roles", ["user_id"], name: "i_organization_roles_user_id"

  create_table "organizations", force: :cascade do |t|
    t.string   "name"
    t.string   "prefix"
    t.text     "description"
    t.integer  "group_id",       limit: nil
    t.integer  "image_model_id", limit: nil
    t.integer  "lock_version",               precision: 38, default: 0
    t.datetime "created_at",                                                null: false
    t.datetime "updated_at",                                                null: false
    t.boolean  "corporate",      limit: nil,                default: false, null: false
  end

  add_index "organizations", ["corporate"], name: "i_organizations_corporate"
  add_index "organizations", ["group_id"], name: "i_organizations_group_id"
  add_index "organizations", ["image_model_id"], name: "i_organizations_image_model_id"
  add_index "organizations", ["name"], name: "index_organizations_on_name"
  add_index "organizations", ["prefix"], name: "index_organizations_on_prefix", unique: true

  create_table "periods", force: :cascade do |t|
    t.integer  "number",                      precision: 38
    t.text     "description"
    t.datetime "start"
    t.datetime "end"
    t.integer  "organization_id", limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "periods", ["end"], name: "index_periods_on_end"
  add_index "periods", ["number"], name: "index_periods_on_number"
  add_index "periods", ["organization_id"], name: "i_periods_organization_id"
  add_index "periods", ["start"], name: "index_periods_on_start"

  create_table "plan_items", force: :cascade do |t|
    t.string   "project"
    t.datetime "start"
    t.datetime "end"
    t.string   "predecessors"
    t.integer  "order_number",                 precision: 38
    t.integer  "plan_id",          limit: nil
    t.integer  "business_unit_id", limit: nil
    t.datetime "created_at",                                  null: false
    t.datetime "updated_at",                                  null: false
  end

  add_index "plan_items", ["business_unit_id"], name: "i_plan_items_business_unit_id"
  add_index "plan_items", ["plan_id"], name: "index_plan_items_on_plan_id"

  create_table "plans", force: :cascade do |t|
    t.integer  "period_id",       limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "organization_id", limit: nil
  end

  add_index "plans", ["organization_id"], name: "index_plans_on_organization_id"
  add_index "plans", ["period_id"], name: "index_plans_on_period_id"

  create_table "polls", force: :cascade do |t|
    t.text     "comments"
    t.boolean  "answered",         limit: nil,                default: false
    t.integer  "lock_version",                 precision: 38, default: 0
    t.integer  "user_id",          limit: nil
    t.integer  "questionnaire_id", limit: nil
    t.integer  "pollable_id",      limit: nil
    t.string   "pollable_type"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.integer  "organization_id",  limit: nil
    t.string   "access_token"
    t.string   "customer_email"
  end

  add_index "polls", ["customer_email"], name: "index_polls_on_customer_email"
  add_index "polls", ["organization_id"], name: "index_polls_on_organization_id"
  add_index "polls", ["questionnaire_id"], name: "i_polls_questionnaire_id"

  create_table "privileges", force: :cascade do |t|
    t.string   "module",     limit: 100
    t.boolean  "read",       limit: nil, default: false
    t.boolean  "modify",     limit: nil, default: false
    t.boolean  "erase",      limit: nil, default: false
    t.boolean  "approval",   limit: nil, default: false
    t.integer  "role_id",    limit: nil
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
  end

  add_index "privileges", ["role_id"], name: "index_privileges_on_role_id"

  create_table "process_controls", force: :cascade do |t|
    t.string   "name"
    t.integer  "order",                        precision: 38
    t.integer  "best_practice_id", limit: nil
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
    t.boolean  "obsolete",         limit: nil,                default: false
  end

  add_index "process_controls", ["best_practice_id"], name: "i_pro_con_bes_pra_id"
  add_index "process_controls", ["obsolete"], name: "i_process_controls_obsolete"

  create_table "questionnaires", force: :cascade do |t|
    t.string   "name"
    t.integer  "lock_version",                    precision: 38, default: 0
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
    t.integer  "organization_id",     limit: nil
    t.string   "pollable_type"
    t.string   "email_subject"
    t.string   "email_link"
    t.string   "email_text"
    t.string   "email_clarification"
  end

  add_index "questionnaires", ["name"], name: "index_questionnaires_on_name"
  add_index "questionnaires", ["organization_id"], name: "i_que_org_id"

  create_table "questions", force: :cascade do |t|
    t.integer  "sort_order",                   precision: 38
    t.integer  "answer_type",                  precision: 38
    t.text     "question"
    t.integer  "questionnaire_id", limit: nil
    t.integer  "lock_version",                 precision: 38, default: 0
    t.datetime "created_at",                                              null: false
    t.datetime "updated_at",                                              null: false
  end

  add_index "questions", ["questionnaire_id"], name: "i_questions_questionnaire_id"

  create_table "related_user_relations", force: :cascade do |t|
    t.integer  "user_id",         limit: nil
    t.integer  "related_user_id", limit: nil
    t.datetime "created_at",                  null: false
    t.datetime "updated_at",                  null: false
  end

  add_index "related_user_relations", ["user_id", "related_user_id"], name: "ibff96752fbe4d0f3af118e7ce3391"

  create_table "repcat$_audit_attribute", comment: "Information about attributes automatically maintained for replication", primary_key: "attribute", force: :cascade do |t|
    t.integer "data_type_id", limit: nil,                null: false, comment: "Datatype of the attribute value"
    t.integer "data_length",              precision: 38,              comment: "Length of the attribute value in byte"
    t.string  "source",       limit: 92,                 null: false, comment: "Name of the function which returns the attribute value"
  end

  create_table "repcat$_audit_column", comment: "Information about columns in all shadow tables for all replicated tables in the database", id: false, force: :cascade do |t|
    t.string  "sname",                 limit: 30,  null: false, comment: "Owner of the shadow table"
    t.string  "oname",                 limit: 30,  null: false, comment: "Name of the shadow table"
    t.string  "column_name",           limit: 30,  null: false, comment: "Name of the column in the shadow table"
    t.string  "base_sname",            limit: 30,  null: false, comment: "Owner of replicated table"
    t.string  "base_oname",            limit: 30,  null: false, comment: "Name of the replicated table"
    t.integer "base_conflict_type_id", limit: nil, null: false, comment: "Type of conflict"
    t.string  "base_reference_name",   limit: 30,  null: false, comment: "Table name, unique constraint name, or column group name"
    t.string  "attribute",             limit: 30,  null: false, comment: "Description of the attribute"
  end

  add_index "repcat$_audit_column", ["attribute"], name: "repcat$_audit_column_f1_idx"
  add_index "repcat$_audit_column", ["base_sname", "base_oname", "base_conflict_type_id", "base_reference_name"], name: "repcat$_audit_column_f2_idx"

  create_table "repcat$_column_group", comment: "All column groups of replicated tables in the database", id: false, force: :cascade do |t|
    t.string "sname",         limit: 30, null: false, comment: "Owner of replicated object"
    t.string "oname",         limit: 30, null: false, comment: "Name of the replicated object"
    t.string "group_name",    limit: 30, null: false, comment: "Name of the column group"
    t.string "group_comment", limit: 80,              comment: "Description of the column group"
  end

  create_table "repcat$_conflict", comment: "All conflicts for which users have specified resolutions in the database", id: false, force: :cascade do |t|
    t.string  "sname",            limit: 30,  null: false, comment: "Owner of replicated object"
    t.string  "oname",            limit: 30,  null: false, comment: "Name of the replicated object"
    t.integer "conflict_type_id", limit: nil, null: false, comment: "Type of conflict"
    t.string  "reference_name",   limit: 30,  null: false, comment: "Table name, unique constraint name, or column group name"
  end

  create_table "repcat$_ddl", comment: "Arguments that do not fit in a single repcat log record", id: false, force: :cascade do |t|
    t.integer "log_id",  limit: nil,                             comment: "Identifying number of the repcat log record"
    t.string  "source",  limit: 128,                             comment: "Name of the database at which the request originated"
    t.boolean "role",    limit: nil,                             comment: "Is this database the masterdef for the request"
    t.string  "master",  limit: 128,                             comment: "Name of the database that processes this request"
    t.integer "line",                 precision: 38,             comment: "Ordering of records within a single request"
    t.string  "text",    limit: 2000,                            comment: "Portion of an argument"
    t.integer "ddl_num",              precision: 38, default: 1, comment: "Ordering of DDLs to execute"
  end

  add_index "repcat$_ddl", ["log_id", "source", "role", "master", "line"], name: "repcat$_ddl", unique: true
  add_index "repcat$_ddl", ["log_id", "source", "role", "master"], name: "repcat$_ddl_index"

  create_table "repcat$_exceptions", comment: "Repcat processing exceptions table.", primary_key: "exception_id", force: :cascade do |t|
    t.string  "user_name",     limit: 30,   comment: "User name of user submitting the exception."
    t.text    "request",                    comment: "Originating request containing the exception."
    t.decimal "job",                        comment: "Originating job containing the exception."
    t.date    "error_date",                 comment: "Date of occurance for the exception."
    t.decimal "error_number",               comment: "Error number generating the exception."
    t.string  "error_message", limit: 4000, comment: "Error message associated with the error generating the exception."
    t.decimal "line_number",                comment: "Line number of the exception."
  end

  create_table "repcat$_extension", comment: "Information about replication extension requests", primary_key: "extension_id", force: :cascade do |t|
    t.decimal "extension_code",                          comment: "Kind of replication extension"
    t.string  "masterdef",                   limit: 128, comment: "Master definition site for replication extension"
    t.boolean "export_required",             limit: nil, comment: "YES if this extension requires an export, and NO if no export is required"
    t.integer "repcatlog_id",                limit: nil, comment: "Identifier of repcatlog records related to replication extension"
    t.decimal "extension_status",                        comment: "Status of replication extension"
    t.decimal "flashback_scn",                           comment: "Flashback_scn for export or change-based recovery for replication extension"
    t.boolean "push_to_mdef",                limit: nil, comment: "YES if existing masters partially push to masterdef, NO if no pushing"
    t.boolean "push_to_new",                 limit: nil, comment: "YES if existing masters partially push to new masters, NO if no pushing"
    t.decimal "percentage_for_catchup_mdef",             comment: "Fraction of push to masterdef cycle devoted to catching up"
    t.decimal "cycle_seconds_mdef",                      comment: "Length of push to masterdef cycle when catching up"
    t.decimal "percentage_for_catchup_new",              comment: "Fraction of push to new masters cycle devoted to catching up"
    t.decimal "cycle_seconds_new",                       comment: "Length of push to new masters cycle when catching up"
  end

  create_table "repcat$_flavor_objects", comment: "Replicated objects in flavors", id: false, force: :cascade do |t|
    t.integer "flavor_id",       limit: nil,                    null: false, comment: "Flavor identifier"
    t.string  "gowner",          limit: 30,  default: "PUBLIC", null: false, comment: "Owner of the object group containing object"
    t.string  "gname",           limit: 30,                     null: false, comment: "Object group containing object"
    t.string  "sname",           limit: 30,                     null: false, comment: "Schema containing object"
    t.string  "oname",           limit: 30,                     null: false, comment: "Name of object"
    t.decimal "type",                                           null: false, comment: "Object type"
    t.decimal "version#",                                                    comment: "Version# of a user-defined type"
    t.raw     "hashcode",        limit: 17,                                  comment: "Hashcode of a user-defined type"
    t.raw     "columns_present", limit: 125,                                 comment: "For tables, encoded mapping of columns present"
  end

  add_index "repcat$_flavor_objects", ["flavor_id", "gname", "gowner"], name: "repcat$_flavor_objects_fg"
  add_index "repcat$_flavor_objects", ["gname", "flavor_id", "gowner"], name: "repcat$_flavor_objects_fk2_idx"
  add_index "repcat$_flavor_objects", ["gname", "gowner"], name: "repcat$_flavor_objects_fk1_idx"

  create_table "repcat$_flavors", comment: "Flavors defined for replicated object groups", id: false, force: :cascade do |t|
    t.integer "flavor_id",     limit: nil,                    null: false, comment: "Flavor identifier, unique within object group"
    t.string  "gowner",        limit: 30,  default: "PUBLIC",              comment: "Owner of the object group"
    t.string  "gname",         limit: 30,                     null: false, comment: "Name of the object group"
    t.string  "fname",         limit: 30,                                  comment: "Name of the flavor"
    t.date    "creation_date",                                             comment: "Date on which the flavor was created"
    t.decimal "created_by",                default: 0.0,                   comment: "Identifier of user that created the flavor"
    t.boolean "published",     limit: nil, default: false,                 comment: "Indicates whether flavor is published (Y/N) or obsolete (O)"
  end

  add_index "repcat$_flavors", ["fname"], name: "repcat$_flavors_fname"
  add_index "repcat$_flavors", ["gname", "flavor_id", "gowner"], name: "repcat$_flavors_unq1", unique: true
  add_index "repcat$_flavors", ["gname", "fname", "gowner"], name: "repcat$_flavors_gname", unique: true
  add_index "repcat$_flavors", ["gname", "gowner"], name: "repcat$_flavors_fk1_idx"

  create_table "repcat$_generated", comment: "Objects generated to support replication", id: false, force: :cascade do |t|
    t.string  "sname",            limit: 30,                 null: false, comment: "Schema containing the generated object"
    t.string  "oname",            limit: 30,                 null: false, comment: "Name of the generated object"
    t.integer "type",                         precision: 38, null: false, comment: "Type of the generated object"
    t.decimal "reason",                                                   comment: "Reason the object was generated"
    t.string  "base_sname",       limit: 30,                 null: false, comment: "Name of the object's owner"
    t.string  "base_oname",       limit: 30,                 null: false, comment: "Name of the object"
    t.integer "base_type",                    precision: 38, null: false, comment: "Type of the object"
    t.string  "package_prefix",   limit: 30,                              comment: "Prefix for package wrapper"
    t.string  "procedure_prefix", limit: 30,                              comment: "Procedure prefix for package wrapper or procedure wrapper"
    t.boolean "distributed",      limit: nil,                             comment: "Is the generated object separately generated at each master"
  end

  add_index "repcat$_generated", ["base_sname", "base_oname", "base_type"], name: "repcat$_generated_n1"
  add_index "repcat$_generated", ["sname", "oname", "type"], name: "repcat$_repgen_prnt_idx"

  create_table "repcat$_grouped_column", comment: "Columns in all column groups of replicated tables in the database", id: false, force: :cascade do |t|
    t.string  "sname",       limit: 30, null: false, comment: "Owner of replicated object"
    t.string  "oname",       limit: 30, null: false, comment: "Name of the replicated object"
    t.string  "group_name",  limit: 30, null: false, comment: "Name of the column group"
    t.string  "column_name", limit: 30, null: false, comment: "Name of the column in the column group"
    t.decimal "pos",                    null: false, comment: "Position of a column or an attribute in the table"
  end

  add_index "repcat$_grouped_column", ["sname", "oname", "group_name"], name: "repcat$_grouped_column_f1_idx"

  create_table "repcat$_instantiation_ddl", comment: "Table containing supplementary DDL to be executed during instantiation.", id: false, force: :cascade do |t|
    t.integer "refresh_template_id", limit: nil, null: false, comment: "Primary key of template containing supplementary DDL."
    t.text    "ddl_text",                                     comment: "Supplementary DDL string."
    t.decimal "ddl_num",                         null: false, comment: "Column for ordering of supplementary DDL."
    t.decimal "phase",                           null: false, comment: "Phase to execute the DDL string."
  end

  create_table "repcat$_key_columns", comment: "Primary columns for a table using column-level replication", id: false, force: :cascade do |t|
    t.string  "sname", limit: 30,                null: false, comment: "Schema containing table"
    t.string  "oname", limit: 30,                null: false, comment: "Name of the table"
    t.integer "type",             precision: 38,              comment: "Type identifier"
    t.string  "col",   limit: 30,                null: false, comment: "Column in the table"
  end

  add_index "repcat$_key_columns", ["sname", "oname", "type"], name: "repcat$_key_columns_prnt_idx"

  create_table "repcat$_object_parms", id: false, force: :cascade do |t|
    t.integer "template_parameter_id", limit: nil, null: false, comment: "Primary key of template parameter."
    t.integer "template_object_id",    limit: nil, null: false, comment: "Primary key of object using the paramter."
  end

  add_index "repcat$_object_parms", ["template_object_id"], name: "repcat$_object_parms_n2"

  create_table "repcat$_object_types", comment: "Internal table for template object types.", primary_key: "object_type_id", force: :cascade do |t|
    t.string "object_type_name", limit: 200,  comment: "Descriptive name for the object type."
    t.raw    "flags",            limit: 255,  comment: "Internal flags for object type processing."
    t.string "spare1",           limit: 4000, comment: "Reserved for future use."
  end

  create_table "repcat$_parameter_column", comment: "All columns used for resolving conflicts in the database", id: false, force: :cascade do |t|
    t.string  "sname",                 limit: 30,   null: false, comment: "Owner of replicated object"
    t.string  "oname",                 limit: 30,   null: false, comment: "Name of the replicated object"
    t.integer "conflict_type_id",      limit: nil,  null: false, comment: "Type of conflict"
    t.string  "reference_name",        limit: 30,   null: false, comment: "Table name, unique constraint name, or column group name"
    t.decimal "sequence_no",                        null: false, comment: "Ordering on resolution"
    t.string  "parameter_table_name",  limit: 30,   null: false, comment: "Name of the table to which the parameter column belongs"
    t.string  "parameter_column_name", limit: 4000,              comment: "Name of the parameter column used for resolving the conflict"
    t.decimal "parameter_sequence_no",              null: false, comment: "Ordering on parameter column"
    t.decimal "column_pos",                         null: false, comment: "Column position of an attribute or a column"
    t.decimal "attribute_sequence_no",                           comment: "Sequence number for an attribute of an ADT/pkREF column or a scalar column"
  end

  add_index "repcat$_parameter_column", ["sname", "oname", "conflict_type_id", "reference_name", "sequence_no"], name: "repcat$_parameter_column_f1_i"

  create_table "repcat$_priority", comment: "Values and their corresponding priorities in all priority groups in the database", id: false, force: :cascade do |t|
    t.string  "sname",            limit: 30,   null: false, comment: "Name of the replicated object group"
    t.string  "priority_group",   limit: 30,   null: false, comment: "Name of the priority group"
    t.decimal "priority",                      null: false, comment: "Priority of the value"
    t.raw     "raw_value",                                  comment: "Raw value"
    t.string  "char_value",                                 comment: "Blank-padded character string"
    t.decimal "number_value",                               comment: "Numeric value"
    t.date    "date_value",                                 comment: "Date value"
    t.string  "varchar2_value",   limit: 4000,              comment: "Character string"
    t.string  "nchar_value",      limit: nil,               comment: "NCHAR string"
    t.string  "nvarchar2_value",  limit: nil,               comment: "NVARCHAR2 string"
    t.string  "large_char_value", limit: 2000,              comment: "Blank-padded character string over 255 characters"
  end

  add_index "repcat$_priority", ["priority_group", "sname"], name: "repcat$_priority_f1_idx"

  create_table "repcat$_priority_group", comment: "Information about all priority groups in the database", id: false, force: :cascade do |t|
    t.string  "sname",             limit: 30,                 null: false, comment: "Name of the replicated object group"
    t.string  "priority_group",    limit: 30,                 null: false, comment: "Name of the priority group"
    t.integer "data_type_id",      limit: nil,                null: false, comment: "Datatype of the value in the priority group"
    t.integer "fixed_data_length",             precision: 38,              comment: "Length of the value in bytes if the datatype is CHAR"
    t.string  "priority_comment",  limit: 80,                              comment: "Description of the priority group"
  end

  add_index "repcat$_priority_group", ["sname", "priority_group", "data_type_id", "fixed_data_length"], name: "repcat$_priority_group_u1", unique: true

  create_table "repcat$_refresh_templates", comment: "Primary table containing deployment template information.", primary_key: "refresh_template_id", force: :cascade do |t|
    t.string   "owner",                 limit: 30,               null: false, comment: "Owner of the refresh group template."
    t.string   "refresh_group_name",    limit: 30,               null: false, comment: "Name of the refresh group to create during instantiation."
    t.string   "refresh_template_name", limit: 30,               null: false, comment: "Name of the refresh group template."
    t.string   "template_comment",      limit: 2000,                          comment: "Optional comment field for the refresh group template."
    t.boolean  "public_template",       limit: nil,                           comment: "Flag specifying public template or private template."
    t.datetime "last_modified",                                               comment: "Date the row was last modified."
    t.decimal  "modified_by",                                                 comment: "User id of the user that modified the row."
    t.date     "creation_date",                                               comment: "Date the row was created."
    t.decimal  "created_by",                                                  comment: "User id of the user that created the row."
    t.integer  "refresh_group_id",      limit: nil,  default: 0, null: false, comment: "Internal primary key to default refresh group for the template."
    t.integer  "template_type_id",      limit: nil,  default: 1, null: false, comment: "Internal primary key to the template types."
    t.integer  "template_status_id",    limit: nil,  default: 0, null: false, comment: "Internal primary key to the template status table."
    t.raw      "flags",                 limit: 255,                           comment: "Internal flags for the template."
    t.string   "spare1",                limit: 4000,                          comment: "Reserved for future use."
  end

  add_index "repcat$_refresh_templates", ["refresh_template_name"], name: "repcat$_refresh_templates_u1", unique: true

  create_table "repcat$_repcat", comment: "Information about all replicated object groups", id: false, force: :cascade do |t|
    t.string  "gowner",         limit: 30,                 default: "PUBLIC",   null: false, comment: "Owner of the object group"
    t.string  "sname",          limit: 30,                                      null: false, comment: "Name of the replicated object group"
    t.boolean "master",         limit: nil,                                                  comment: "Is the site a master site for the replicated object group"
    t.integer "status",                     precision: 38,                                   comment: "If the site is a master, the master's status"
    t.string  "schema_comment", limit: 80,                                                   comment: "Description of the replicated object group"
    t.integer "flavor_id",      limit: nil,                                                  comment: "Flavor identifier"
    t.raw     "flag",           limit: 4,                  default: "00000000",              comment: "Miscellaneous repgroup info"
  end

  create_table "repcat$_repcatlog", comment: "Information about asynchronous administration requests", id: false, force: :cascade do |t|
    t.decimal  "version",                                               comment: "Version of the repcat log record"
    t.integer  "id",           limit: nil,                 null: false, comment: "Identifying number of repcat log record"
    t.string   "source",       limit: 128,                 null: false, comment: "Name of the database at which the request originated"
    t.string   "userid",       limit: 30,                               comment: "Name of the user who submitted the request"
    t.datetime "timestamp",                                             comment: "When the request was submitted"
    t.boolean  "role",         limit: nil,                 null: false, comment: "Is this database the masterdef for the request"
    t.string   "master",       limit: 128,                 null: false, comment: "Name of the database that processes this request$_ddl"
    t.string   "sname",        limit: 30,                               comment: "Schema of replicated object"
    t.integer  "request",                   precision: 38,              comment: "Name of the requested operation"
    t.string   "oname",        limit: 30,                               comment: "Replicated object name, if applicable"
    t.integer  "type",                      precision: 38,              comment: "Type of replicated object, if applicable"
    t.string   "a_comment",    limit: 2000,                             comment: "Textual argument used for comments"
    t.boolean  "bool_arg",     limit: nil,                              comment: "Boolean argument"
    t.boolean  "ano_bool_arg", limit: nil,                              comment: "Another Boolean argument"
    t.integer  "int_arg",                   precision: 38,              comment: "Integer argument"
    t.integer  "ano_int_arg",               precision: 38,              comment: "Another integer argument"
    t.integer  "lines",                     precision: 38,              comment: "The number of rows in system.repcat$_ddl at the processing site"
    t.integer  "status",                    precision: 38,              comment: "Status of the request at this database"
    t.string   "message",      limit: 200,                              comment: "Error message associated with processing the request"
    t.decimal  "errnum",                                                comment: "Oracle error number associated with processing the request"
    t.string   "gname",        limit: 30,                               comment: "Name of the replicated object group"
  end

  add_index "repcat$_repcatlog", ["gname", "sname", "oname", "type"], name: "repcat$_repcatlog_gname"

  create_table "repcat$_repcolumn", comment: "Replicated columns for a table sorted alphabetically in ascending order", id: false, force: :cascade do |t|
    t.string  "sname",       limit: 30,                                       null: false, comment: "Name of the object owner"
    t.string  "oname",       limit: 30,                                       null: false, comment: "Name of the object"
    t.integer "type",                     precision: 38,                      null: false, comment: "Type of the object"
    t.string  "cname",       limit: 30,                                       null: false, comment: "Column name"
    t.string  "lcname",      limit: 4000,                                                  comment: "Long column name"
    t.raw     "toid",        limit: 16,                                                    comment: "Type object identifier of a user-defined type"
    t.decimal "version#",                                                                  comment: "Version# of a column of user-defined type"
    t.raw     "hashcode",    limit: 17,                                                    comment: "Hashcode of a column of user-defined type"
    t.string  "ctype_name",  limit: 30
    t.string  "ctype_owner", limit: 30
    t.integer "id",          limit: nil,                                                   comment: "Column ID"
    t.decimal "pos",                                                                       comment: "Ordering of column used as IN parameter in the replication procedures"
    t.string  "top",         limit: 30,                                                    comment: "Top column name for an attribute"
    t.raw     "flag",        limit: 2,                   default: "0000",                  comment: "Replication information about column"
    t.decimal "ctype",                                                                     comment: "Type of the column"
    t.decimal "length",                                                                    comment: "Length of the column in bytes"
    t.decimal "precision#",                                                                comment: "Length: decimal digits (NUMBER) or binary digits (FLOAT)"
    t.decimal "scale",                                                                     comment: "Digits to right of decimal point in a number"
    t.decimal "null$",                                                                     comment: "Does column allow NULL values?"
    t.decimal "charsetid",                                                                 comment: "Character set identifier"
    t.decimal "charsetform",                                                               comment: "Character set form"
    t.raw     "property",    limit: 4,                   default: "00000000"
    t.decimal "clength",                                                                   comment: "The maximum length of the column in characters"
  end

  add_index "repcat$_repcolumn", ["sname", "oname", "type"], name: "repcat$_repcolumn_fk_idx"

  create_table "repcat$_repgroup_privs", comment: "Information about users who are registered for object group privileges", id: false, force: :cascade do |t|
    t.decimal  "userid",                              comment: "OBSOLETE COLUMN: Identifying number of the user"
    t.string   "username",    limit: 30, null: false, comment: "Identifying name of the registered user"
    t.string   "gowner",      limit: 30,              comment: "Owner of the replicated object group"
    t.string   "gname",       limit: 30,              comment: "Name of the replicated object group"
    t.decimal  "global_flag",            null: false, comment: "1 if gname is NULL, 0 otherwise"
    t.datetime "created",                null: false, comment: "Registration date"
    t.decimal  "privilege",                           comment: "Registered privileges"
  end

  add_index "repcat$_repgroup_privs", ["global_flag", "username"], name: "repcat$_repgroup_privs_n1"
  add_index "repcat$_repgroup_privs", ["gname", "gowner"], name: "repcat$_repgroup_privs_fk_idx"
  add_index "repcat$_repgroup_privs", ["username", "gname", "gowner"], name: "repcat$_repgroup_privs_uk", unique: true

  create_table "repcat$_repobject", comment: "Information about replicated objects", id: false, force: :cascade do |t|
    t.string  "sname",          limit: 30,                                      null: false, comment: "Name of the object owner"
    t.string  "oname",          limit: 30,                                      null: false, comment: "Name of the object"
    t.integer "type",                       precision: 38,                      null: false, comment: "Type of the object"
    t.decimal "version#",                                                                    comment: "Version of objects of TYPE"
    t.raw     "hashcode",       limit: 17,                                                   comment: "Hashcode of objects of TYPE"
    t.integer "id",             limit: nil,                                                  comment: "Identifier of the local object"
    t.string  "object_comment", limit: 80,                                                   comment: "Description of the replicated object"
    t.integer "status",                     precision: 38,                                   comment: "Status of the last create or alter request on the local object"
    t.integer "genpackage",                 precision: 38,                                   comment: "Status of whether the object needs to generate replication package"
    t.integer "genplogid",                  precision: 38,                                   comment: "Log id of message sent for generating package support"
    t.integer "gentrigger",                 precision: 38,                                   comment: "Status of whether the object needs to generate replication trigger"
    t.integer "gentlogid",                  precision: 38,                                   comment: "Log id of message sent for generating trigger support"
    t.string  "gowner",         limit: 30,                                                   comment: "Owner of the object's object group"
    t.string  "gname",          limit: 30,                                                   comment: "Name of the object's object group"
    t.raw     "flag",           limit: 4,                  default: "00000000",              comment: "Information about replicated object"
  end

  add_index "repcat$_repobject", ["gname", "gowner"], name: "repcat$_repobject_prnt_idx"
  add_index "repcat$_repobject", ["gname", "oname", "type", "gowner"], name: "repcat$_repobject_gname"

  create_table "repcat$_repprop", comment: "Propagation information about replicated objects", id: false, force: :cascade do |t|
    t.string  "sname",             limit: 30,                                null: false, comment: "Name of the object owner"
    t.string  "oname",             limit: 30,                                null: false, comment: "Name of the object"
    t.integer "type",                          precision: 38,                null: false, comment: "Type of the object"
    t.string  "dblink",            limit: 128,                               null: false, comment: "Destination database for propagation"
    t.integer "how",                           precision: 38,                             comment: "Propagation choice for the destination database"
    t.string  "propagate_comment", limit: 80,                                             comment: "Description of the propagation choice"
    t.decimal "delivery_order",                                                           comment: "Value of delivery order when the master was added"
    t.decimal "recipient_key",                                                            comment: "Recipient key for sname and oname, used in joining with def$_aqcall"
    t.raw     "extension_id",      limit: 16,                 default: "00",              comment: "Identifier of any active extension request"
  end

  add_index "repcat$_repprop", ["dblink", "how", "extension_id", "recipient_key"], name: "repcat$_repprop_dblink_how"
  add_index "repcat$_repprop", ["recipient_key"], name: "repcat$_repprop_key_index"
  add_index "repcat$_repprop", ["sname", "dblink"], name: "repcat$_repprop_prnt2_idx"
  add_index "repcat$_repprop", ["sname", "oname", "type"], name: "repcat$_repprop_prnt_idx"

  create_table "repcat$_repschema", comment: "N-way replication information", id: false, force: :cascade do |t|
    t.string  "gowner",         limit: 30,  default: "PUBLIC", null: false, comment: "Owner of the replicated object group"
    t.string  "sname",          limit: 30,                     null: false, comment: "Name of the replicated object group"
    t.string  "dblink",         limit: 128,                    null: false, comment: "A database site replicating the object group"
    t.boolean "masterdef",      limit: nil,                                 comment: "Is the database the master definition site for the replicated object group"
    t.boolean "snapmaster",     limit: nil,                                 comment: "For a snapshot site, is this the current refresh_master"
    t.string  "master_comment", limit: 80,                                  comment: "Description of the database site"
    t.boolean "master",         limit: nil,                                 comment: "Redundant information from repcat$_repcat.master"
    t.decimal "prop_updates",               default: 0.0,                   comment: "Number of requested updates for master in repcat$_repprop"
    t.boolean "my_dblink",      limit: nil,                                 comment: "A sanity check after import: is this master the current site"
    t.raw     "extension_id",   limit: 16,  default: "00",                  comment: "Dummy column for foreign key"
  end

  add_index "repcat$_repschema", ["dblink", "extension_id"], name: "repcat$_repschema_dest_idx"
  add_index "repcat$_repschema", ["sname", "gowner"], name: "repcat$_repschema_prnt_idx"

  create_table "repcat$_resol_stats_control", comment: "Information about statistics collection for conflict resolutions for all replicated tables in the database", id: false, force: :cascade do |t|
    t.string   "sname",                 limit: 30,                null: false, comment: "Owner of replicated object"
    t.string   "oname",                 limit: 30,                null: false, comment: "Name of the replicated object"
    t.datetime "created",                                         null: false, comment: "Timestamp for which statistics collection was first started"
    t.integer  "status",                           precision: 38, null: false, comment: "Status of statistics collection: ACTIVE, CANCELLED"
    t.date     "status_update_date",                              null: false, comment: "Timestamp for which the status was last updated"
    t.date     "purged_date",                                                  comment: "Timestamp for the last purge of statistics data"
    t.date     "last_purge_start_date",                                        comment: "The last start date of the statistics purging date range"
    t.date     "last_purge_end_date",                                          comment: "The last end date of the statistics purging date range"
  end

  create_table "repcat$_resolution", comment: "Description of all conflict resolutions in the database", id: false, force: :cascade do |t|
    t.string  "sname",              limit: 30,  null: false, comment: "Owner of replicated object"
    t.string  "oname",              limit: 30,  null: false, comment: "Name of the replicated object"
    t.integer "conflict_type_id",   limit: nil, null: false, comment: "Type of conflict"
    t.string  "reference_name",     limit: 30,  null: false, comment: "Table name, unique constraint name, or column group name"
    t.decimal "sequence_no",                    null: false, comment: "Ordering on resolution"
    t.string  "method_name",        limit: 80,  null: false, comment: "Name of the conflict resolution method"
    t.string  "function_name",      limit: 92,  null: false, comment: "Name of the resolution function"
    t.string  "priority_group",     limit: 30,               comment: "Name of the priority group used in conflict resolution"
    t.string  "resolution_comment", limit: 80,               comment: "Description of the conflict resolution"
  end

  add_index "repcat$_resolution", ["conflict_type_id", "method_name"], name: "repcat$_resolution_f3_idx"
  add_index "repcat$_resolution", ["sname", "oname", "conflict_type_id", "reference_name"], name: "repcat$_resolution_idx2"

  create_table "repcat$_resolution_method", comment: "All conflict resolution methods in the database", id: false, force: :cascade do |t|
    t.integer "conflict_type_id", limit: nil, null: false, comment: "Type of conflict"
    t.string  "method_name",      limit: 80,  null: false, comment: "Name of the conflict resolution method"
  end

  create_table "repcat$_resolution_statistics", comment: "Statistics for conflict resolutions for all replicated tables in the database", id: false, force: :cascade do |t|
    t.string  "sname",             limit: 30,   null: false, comment: "Owner of replicated object"
    t.string  "oname",             limit: 30,   null: false, comment: "Name of the replicated object"
    t.integer "conflict_type_id",  limit: nil,  null: false, comment: "Type of conflict"
    t.string  "reference_name",    limit: 30,   null: false, comment: "Table name, unique constraint name, or column group name"
    t.string  "method_name",       limit: 80,   null: false, comment: "Name of the conflict resolution method"
    t.string  "function_name",     limit: 92,   null: false, comment: "Name of the resolution function"
    t.string  "priority_group",    limit: 30,                comment: "Name of the priority group used in conflict resolution"
    t.date    "resolved_date",                  null: false, comment: "Timestamp for the resolution of the conflict"
    t.string  "primary_key_value", limit: 2000, null: false, comment: "Primary key of the replicated row (character data)"
  end

  add_index "repcat$_resolution_statistics", ["sname", "oname", "resolved_date", "conflict_type_id", "reference_name", "method_name", "function_name", "priority_group"], name: "repcat$_resolution_stats_n1"

  create_table "repcat$_runtime_parms", id: false, force: :cascade do |t|
    t.integer "runtime_parm_id", limit: nil, comment: "Primary key of the parameter values table."
    t.string  "parameter_name",  limit: 30,  comment: "Name of the parameter."
    t.text    "parm_value",                  comment: "Parameter value."
  end

  add_index "repcat$_runtime_parms", ["runtime_parm_id", "parameter_name"], name: "repcat$_runtime_parms_pk", unique: true

  create_table "repcat$_site_objects", comment: "Table for maintaining database objects deployed at a site.", id: false, force: :cascade do |t|
    t.integer "template_site_id", limit: nil, null: false, comment: "Internal primary key of the template sites table."
    t.string  "sname",            limit: 30,               comment: "Schema containing the deployed database object."
    t.string  "oname",            limit: 30,  null: false, comment: "Name of the deployed database object."
    t.integer "object_type_id",   limit: nil, null: false, comment: "Internal ID of the object type of the deployed database object."
  end

  add_index "repcat$_site_objects", ["template_site_id", "oname", "object_type_id", "sname"], name: "repcat$_site_objects_u1", unique: true
  add_index "repcat$_site_objects", ["template_site_id"], name: "repcat$_site_objects_n1"

  create_table "repcat$_sites_new", comment: "Information about new masters for replication extension", id: false, force: :cascade do |t|
    t.raw     "extension_id",       limit: 16,  null: false, comment: "Globally unique identifier for replication extension"
    t.string  "gowner",             limit: 30,  null: false, comment: "Owner of the object group"
    t.string  "gname",              limit: 30,  null: false, comment: "Name of the replicated object group"
    t.string  "dblink",             limit: 128, null: false, comment: "A database site that will replicate the object group"
    t.boolean "full_instantiation", limit: nil,              comment: "Y if the database uses full-database export or change-based recovery"
    t.decimal "master_status",                               comment: "Instantiation status of the new master"
  end

  add_index "repcat$_sites_new", ["extension_id"], name: "repcat$_sites_new_fk1_idx"
  add_index "repcat$_sites_new", ["gname", "gowner"], name: "repcat$_sites_new_fk2_idx"

  create_table "repcat$_snapgroup", comment: "Snapshot repgroup registration information", id: false, force: :cascade do |t|
    t.string  "gowner",        limit: 30,  default: "PUBLIC", comment: "Owner of the snapshot repgroup"
    t.string  "gname",         limit: 30,                     comment: "Name of the snapshot repgroup"
    t.string  "dblink",        limit: 128,                    comment: "Database site of the snapshot repgroup"
    t.string  "group_comment", limit: 80,                     comment: "Description of the snapshot repgroup"
    t.decimal "rep_type",                                     comment: "Identifier of flavor at snapshot"
    t.integer "flavor_id",     limit: nil
  end

  add_index "repcat$_snapgroup", ["gname", "dblink", "gowner"], name: "i_repcat$_snapgroup1", unique: true

  create_table "repcat$_template_objects", primary_key: "template_object_id", force: :cascade do |t|
    t.integer "refresh_template_id",  limit: nil,                null: false, comment: "Internal primary key of the REPCAT$_REFRESH_TEMPLATES table."
    t.string  "object_name",          limit: 30,                 null: false, comment: "Name of the database object."
    t.decimal "object_type",                                     null: false, comment: "Type of database object."
    t.decimal "object_version#",                                              comment: "Version# of database object of TYPE."
    t.text    "ddl_text",                                                     comment: "DDL string for creating the object or WHERE clause for snapshot query."
    t.string  "master_rollback_seg",  limit: 30,                              comment: "Rollback segment for use during snapshot refreshes."
    t.string  "derived_from_sname",   limit: 30,                              comment: "Schema name of schema containing object this was derived from."
    t.string  "derived_from_oname",   limit: 30,                              comment: "Object name of object this object was derived from."
    t.integer "flavor_id",            limit: nil,                             comment: "Foreign key to the REPCAT$_FLAVORS table."
    t.string  "schema_name",          limit: 30,                              comment: "Schema containing the object."
    t.decimal "ddl_num",                           default: 1.0, null: false, comment: "Order of ddls to execute."
    t.integer "template_refgroup_id", limit: nil,  default: 0,   null: false, comment: "Internal ID of the refresh group to contain the object."
    t.raw     "flags",                limit: 255,                             comment: "Internal flags for the object."
    t.string  "spare1",               limit: 4000,                            comment: "Reserved for future use."
  end

  add_index "repcat$_template_objects", ["object_name", "object_type", "refresh_template_id", "schema_name", "ddl_num"], name: "repcat$_template_objects_u1", unique: true
  add_index "repcat$_template_objects", ["refresh_template_id", "object_name", "schema_name", "object_type"], name: "repcat$_template_objects_n2"
  add_index "repcat$_template_objects", ["refresh_template_id", "object_type"], name: "repcat$_template_objects_n1"

  create_table "repcat$_template_parms", primary_key: "template_parameter_id", force: :cascade do |t|
    t.integer "refresh_template_id", limit: nil,                 null: false, comment: "Internal primary key of the REPCAT$_REFRESH_TEMPLATES table."
    t.string  "parameter_name",      limit: 30,                  null: false, comment: "name of the parameter."
    t.text    "default_parm_value",                                           comment: "Default value for the parameter."
    t.string  "prompt_string",       limit: 2000,                             comment: "String for use in prompting for parameter values."
    t.boolean "user_override",       limit: nil,  default: true,              comment: "User override flag."
  end

  add_index "repcat$_template_parms", ["refresh_template_id", "parameter_name"], name: "repcat$_template_parms_u1", unique: true

  create_table "repcat$_template_refgroups", comment: "Table for maintaining refresh group information for template.", primary_key: "refresh_group_id", force: :cascade do |t|
    t.string  "refresh_group_name",  limit: 30,  null: false, comment: "Name of the refresh group"
    t.integer "refresh_template_id", limit: nil, null: false, comment: "Primary key of the template containing the refresh group."
    t.string  "rollback_seg",        limit: 30,               comment: "Name of the rollback segment to use during refresh."
    t.string  "start_date",          limit: 200,              comment: "Refresh start date."
    t.string  "interval",            limit: 200,              comment: "Refresh interval."
  end

  add_index "repcat$_template_refgroups", ["refresh_group_name"], name: "repcat$_template_refgroups_n1"
  add_index "repcat$_template_refgroups", ["refresh_template_id"], name: "repcat$_template_refgroups_n2"

  create_table "repcat$_template_sites", primary_key: "template_site_id", force: :cascade do |t|
    t.string  "refresh_template_name", limit: 30,  null: false, comment: "Name of the refresh group template."
    t.string  "refresh_group_name",    limit: 30,               comment: "Name of the refresh group to create during instantiation."
    t.string  "template_owner",        limit: 30,               comment: "Owner of the refresh group template."
    t.string  "user_name",             limit: 30,  null: false, comment: "Database user name."
    t.string  "site_name",             limit: 128,              comment: "Name of the site that has instantiated the template."
    t.integer "repapi_site_id",        limit: nil,              comment: "Name of the site that has instantiated the template."
    t.decimal "status",                            null: false, comment: "Obsolete - do not use."
    t.integer "refresh_template_id",   limit: nil,              comment: "Obsolete - do not use."
    t.integer "user_id",               limit: nil,              comment: "Obsolete - do not use."
    t.date    "instantiation_date",                             comment: "Date template was instantiated."
  end

  add_index "repcat$_template_sites", ["refresh_template_name", "user_name", "site_name", "repapi_site_id"], name: "repcat$_template_sites_u1", unique: true

  create_table "repcat$_template_status", comment: "Table for template status and template status codes.", primary_key: "template_status_id", force: :cascade do |t|
    t.string "status_type_name", limit: 100, null: false, comment: "User friendly name for the template status."
  end

  create_table "repcat$_template_targets", comment: "Internal table for tracking potential target databases for templates.", primary_key: "template_target_id", force: :cascade do |t|
    t.string "target_database", limit: 128,  null: false, comment: "Global identifier of the target database."
    t.string "target_comment",  limit: 2000,              comment: "Comment on the target database."
    t.string "connect_string",  limit: 4000,              comment: "The connection descriptor used to connect to the target database."
    t.string "spare1",          limit: 4000,              comment: "The spare column"
  end

  add_index "repcat$_template_targets", ["target_database"], name: "repcat$_template_targets_u1", unique: true

  create_table "repcat$_template_types", comment: "Internal table for maintaining types of templates.", primary_key: "template_type_id", force: :cascade do |t|
    t.string "template_description", limit: 200,  comment: "Description of the template type."
    t.raw    "flags",                limit: 255,  comment: "Bitmap flags controlling each type of template."
    t.string "spare1",               limit: 4000, comment: "Reserved for future expansion."
  end

  create_table "repcat$_user_authorizations", primary_key: "user_authorization_id", force: :cascade do |t|
    t.integer "user_id",             limit: nil, null: false, comment: "Database user id."
    t.integer "refresh_template_id", limit: nil, null: false, comment: "Internal primary key of the REPCAT$_REFRESH_TEMPLATES table."
  end

  add_index "repcat$_user_authorizations", ["refresh_template_id"], name: "repcat$_user_authorizations_n1"
  add_index "repcat$_user_authorizations", ["user_id", "refresh_template_id"], name: "repcat$_user_authorizations_u1", unique: true

  create_table "repcat$_user_parm_values", primary_key: "user_parameter_id", force: :cascade do |t|
    t.integer "template_parameter_id", limit: nil, null: false, comment: "Internal primary key of the REPCAT$_TEMPLATE_PARMS table."
    t.integer "user_id",               limit: nil, null: false, comment: "Database user id."
    t.text    "parm_value",                                     comment: "Value of the parameter for this user."
  end

  add_index "repcat$_user_parm_values", ["template_parameter_id", "user_id"], name: "repcat$_user_parm_values_u1", unique: true

  create_table "resource_classes", force: :cascade do |t|
    t.string   "name"
    t.integer  "unit",                            precision: 38
    t.integer  "resource_class_type",             precision: 38
    t.integer  "organization_id",     limit: nil
    t.integer  "lock_version",                    precision: 38, default: 0
    t.datetime "created_at",                                                 null: false
    t.datetime "updated_at",                                                 null: false
  end

  add_index "resource_classes", ["name"], name: "index_resource_classes_on_name"
  add_index "resource_classes", ["organization_id"], name: "i_res_cla_org_id"

  create_table "resource_utilizations", force: :cascade do |t|
    t.decimal  "units",                              precision: 15, scale: 2
    t.decimal  "cost_per_unit",                      precision: 15, scale: 2
    t.integer  "resource_consumer_id",   limit: nil
    t.string   "resource_consumer_type"
    t.integer  "resource_id",            limit: nil
    t.string   "resource_type"
    t.datetime "created_at",                                                  null: false
    t.datetime "updated_at",                                                  null: false
  end

  add_index "resource_utilizations", ["resource_consumer_id", "resource_consumer_type"], name: "ru_consumer_consumer_type_idx"
  add_index "resource_utilizations", ["resource_id", "resource_type"], name: "ru_resource_resource_type_idx"

  create_table "resources", force: :cascade do |t|
    t.string   "name"
    t.text     "description"
    t.decimal  "cost_per_unit",                 precision: 15, scale: 2
    t.integer  "resource_class_id", limit: nil
    t.integer  "lock_version",                  precision: 38,           default: 0
    t.datetime "created_at",                                                         null: false
    t.datetime "updated_at",                                                         null: false
  end

  add_index "resources", ["resource_class_id"], name: "i_resources_resource_class_id"

  create_table "review_user_assignments", force: :cascade do |t|
    t.integer  "assignment_type",             precision: 38
    t.integer  "review_id",       limit: nil
    t.integer  "user_id",         limit: nil
    t.datetime "created_at",                                 null: false
    t.datetime "updated_at",                                 null: false
  end

  add_index "review_user_assignments", ["review_id", "user_id"], name: "i_rev_use_ass_rev_id_use_id"

  create_table "reviews", force: :cascade do |t|
    t.string   "identification"
    t.text     "description"
    t.text     "survey"
    t.integer  "score",                       precision: 38
    t.integer  "top_scale",                   precision: 38
    t.integer  "achieved_scale",              precision: 38
    t.integer  "period_id",       limit: nil
    t.integer  "plan_item_id",    limit: nil
    t.integer  "file_model_id",   limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "organization_id", limit: nil
  end

  add_index "reviews", ["file_model_id"], name: "index_reviews_on_file_model_id"
  add_index "reviews", ["identification"], name: "i_reviews_identification"
  add_index "reviews", ["organization_id"], name: "i_reviews_organization_id"
  add_index "reviews", ["period_id"], name: "index_reviews_on_period_id"
  add_index "reviews", ["plan_item_id"], name: "index_reviews_on_plan_item_id"

  create_table "roles", force: :cascade do |t|
    t.string   "name"
    t.integer  "role_type",                   precision: 38
    t.integer  "organization_id", limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "roles", ["name"], name: "index_roles_on_name"
  add_index "roles", ["organization_id"], name: "index_roles_on_organization_id"

  create_table "settings", force: :cascade do |t|
    t.string   "name",                                                   null: false
    t.string   "value",                                                  null: false
    t.text     "description"
    t.integer  "organization_id", limit: nil,                            null: false
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "settings", ["name", "organization_id"], name: "i_set_nam_org_id", unique: true
  add_index "settings", ["name"], name: "index_settings_on_name"
  add_index "settings", ["organization_id"], name: "i_settings_organization_id"

# Could not dump table "sqlplus_product_profile" because of following StandardError
#   Unknown type 'LONG' for column 'long_value'

  create_table "users", force: :cascade do |t|
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
    t.boolean  "enable",               limit: nil,                default: false
    t.boolean  "logged_in",            limit: nil,                default: false
    t.boolean  "group_admin",          limit: nil,                default: false
    t.integer  "resource_id",          limit: nil
    t.datetime "last_access"
    t.integer  "manager_id",           limit: nil
    t.integer  "failed_attempts",                  precision: 38, default: 0
    t.text     "notes"
    t.integer  "lock_version",                     precision: 38, default: 0
    t.datetime "created_at",                                                      null: false
    t.datetime "updated_at",                                                      null: false
    t.datetime "hash_changed"
    t.boolean  "hidden",               limit: nil,                default: false
  end

  add_index "users", ["change_password_hash"], name: "i_users_change_password_hash", unique: true
  add_index "users", ["email"], name: "index_users_on_email", unique: true
  add_index "users", ["group_admin"], name: "index_users_on_group_admin"
  add_index "users", ["hidden"], name: "index_users_on_hidden"
  add_index "users", ["manager_id"], name: "index_users_on_manager_id"
  add_index "users", ["resource_id"], name: "index_users_on_resource_id"
  add_index "users", ["user"], name: "index_users_on_user"

  create_table "versions", force: :cascade do |t|
    t.integer  "item_id",         limit: nil
    t.string   "item_type"
    t.string   "event",                                      null: false
    t.integer  "whodunnit",                   precision: 38
    t.text     "object"
    t.datetime "created_at"
    t.boolean  "important",       limit: nil
    t.integer  "organization_id", limit: nil
  end

  add_index "versions", ["created_at"], name: "index_versions_on_created_at"
  add_index "versions", ["important"], name: "index_versions_on_important"
  add_index "versions", ["item_type", "item_id"], name: "i_versions_item_type_item_id"
  add_index "versions", ["organization_id"], name: "i_versions_organization_id"
  add_index "versions", ["whodunnit"], name: "index_versions_on_whodunnit"

  create_table "work_papers", force: :cascade do |t|
    t.string   "name"
    t.string   "code"
    t.integer  "number_of_pages",             precision: 38
    t.text     "description"
    t.integer  "owner_id",        limit: nil
    t.string   "owner_type"
    t.integer  "file_model_id",   limit: nil
    t.integer  "organization_id", limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
  end

  add_index "work_papers", ["file_model_id"], name: "i_work_papers_file_model_id"
  add_index "work_papers", ["organization_id"], name: "i_work_papers_organization_id"
  add_index "work_papers", ["owner_type", "owner_id"], name: "i_wor_pap_own_typ_own_id"

  create_table "workflow_items", force: :cascade do |t|
    t.text     "task"
    t.datetime "start"
    t.datetime "end"
    t.string   "predecessors"
    t.integer  "order_number",             precision: 38
    t.integer  "workflow_id",  limit: nil
    t.datetime "created_at",                              null: false
    t.datetime "updated_at",                              null: false
  end

  add_index "workflow_items", ["workflow_id"], name: "i_workflow_items_workflow_id"

  create_table "workflows", force: :cascade do |t|
    t.integer  "review_id",       limit: nil
    t.integer  "period_id",       limit: nil
    t.integer  "lock_version",                precision: 38, default: 0
    t.datetime "created_at",                                             null: false
    t.datetime "updated_at",                                             null: false
    t.integer  "organization_id", limit: nil
  end

  add_index "workflows", ["organization_id"], name: "i_workflows_organization_id"
  add_index "workflows", ["period_id"], name: "index_workflows_on_period_id"
  add_index "workflows", ["review_id"], name: "index_workflows_on_review_id"

  add_foreign_key "achievements", "benefits", on_delete: :cascade
  add_foreign_key "achievements", "findings", on_delete: :cascade
  add_foreign_key "aq$_internet_agent_privs", "aq$_internet_agents", column: "agent_name", primary_key: "agent_name", name: "agent_must_be_created", on_delete: :cascade
  add_foreign_key "benefits", "organizations", on_delete: :cascade
  add_foreign_key "best_practices", "groups", on_delete: :cascade
  add_foreign_key "best_practices", "organizations", on_delete: :cascade
  add_foreign_key "business_unit_findings", "business_units", on_delete: :cascade
  add_foreign_key "business_unit_findings", "findings", on_delete: :cascade
  add_foreign_key "business_unit_scores", "business_units", on_delete: :cascade
  add_foreign_key "business_unit_scores", "control_objective_items", on_delete: :cascade
  add_foreign_key "business_unit_types", "organizations", on_delete: :cascade
  add_foreign_key "business_units", "business_unit_types", on_delete: :cascade
  add_foreign_key "comments", "users", on_delete: :cascade
  add_foreign_key "conclusion_reviews", "reviews", on_delete: :cascade
  add_foreign_key "control_objective_items", "control_objectives", on_delete: :cascade
  add_foreign_key "control_objective_items", "reviews", on_delete: :cascade
  add_foreign_key "control_objectives", "process_controls", on_delete: :cascade
  add_foreign_key "costs", "users", on_delete: :cascade
  add_foreign_key "def$_calldest", "def$_destination", column: "catchup", primary_key: "catchup", name: "def$_call_destination"
  add_foreign_key "def$_calldest", "def$_destination", column: "dblink", primary_key: "dblink", name: "def$_call_destination"
  add_foreign_key "error_records", "organizations", on_delete: :cascade
  add_foreign_key "error_records", "users", on_delete: :cascade
  add_foreign_key "finding_answers", "file_models", on_delete: :cascade
  add_foreign_key "finding_answers", "findings", on_delete: :cascade
  add_foreign_key "finding_answers", "users", on_delete: :cascade
  add_foreign_key "finding_relations", "findings", column: "related_finding_id", on_delete: :cascade
  add_foreign_key "finding_relations", "findings", on_delete: :cascade
  add_foreign_key "finding_review_assignments", "findings", on_delete: :cascade
  add_foreign_key "finding_review_assignments", "reviews", on_delete: :cascade
  add_foreign_key "finding_user_assignments", "findings", on_delete: :cascade
  add_foreign_key "finding_user_assignments", "users", on_delete: :cascade
  add_foreign_key "findings", "control_objective_items", on_delete: :cascade
  add_foreign_key "findings", "findings", column: "repeated_of_id", on_delete: :cascade
  add_foreign_key "ldap_configs", "organizations", on_delete: :cascade
  add_foreign_key "login_records", "organizations", on_delete: :cascade
  add_foreign_key "login_records", "users", on_delete: :cascade
  add_foreign_key "mview$_adv_ajg", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_ajg_fk"
  add_foreign_key "mview$_adv_basetable", "mview$_adv_workload", column: "queryid#", primary_key: "queryid#", name: "mview$_adv_basetable_fk"
  add_foreign_key "mview$_adv_clique", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_clique_fk"
  add_foreign_key "mview$_adv_eligible", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_eligible_fk"
  add_foreign_key "mview$_adv_exceptions", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_exception_fk"
  add_foreign_key "mview$_adv_filterinstance", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_filterinstance_fk"
  add_foreign_key "mview$_adv_fjg", "mview$_adv_ajg", column: "ajgid#", primary_key: "ajgid#", name: "mview$_adv_fjg_fk"
  add_foreign_key "mview$_adv_gc", "mview$_adv_fjg", column: "fjgid#", primary_key: "fjgid#", name: "mview$_adv_gc_fk"
  add_foreign_key "mview$_adv_info", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_info_fk"
  add_foreign_key "mview$_adv_journal", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_journal_fk"
  add_foreign_key "mview$_adv_level", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_level_fk"
  add_foreign_key "mview$_adv_output", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_output_fk"
  add_foreign_key "mview$_adv_rollup", "mview$_adv_level", column: "clevelid#", primary_key: "levelid#", name: "mview$_adv_rollup_cfk"
  add_foreign_key "mview$_adv_rollup", "mview$_adv_level", column: "plevelid#", primary_key: "levelid#", name: "mview$_adv_rollup_pfk"
  add_foreign_key "mview$_adv_rollup", "mview$_adv_level", column: "runid#", primary_key: "runid#", name: "mview$_adv_rollup_cfk"
  add_foreign_key "mview$_adv_rollup", "mview$_adv_level", column: "runid#", primary_key: "runid#", name: "mview$_adv_rollup_pfk"
  add_foreign_key "mview$_adv_rollup", "mview$_adv_log", column: "runid#", primary_key: "runid#", name: "mview$_adv_rollup_fk"
  add_foreign_key "notification_relations", "notifications", on_delete: :cascade
  add_foreign_key "notifications", "users", column: "user_who_confirm_id", on_delete: :cascade
  add_foreign_key "notifications", "users", on_delete: :cascade
  add_foreign_key "old_passwords", "users", on_delete: :cascade
  add_foreign_key "organization_roles", "organizations", on_delete: :cascade
  add_foreign_key "organization_roles", "roles", on_delete: :cascade
  add_foreign_key "organization_roles", "users", on_delete: :cascade
  add_foreign_key "organizations", "groups", on_delete: :cascade
  add_foreign_key "organizations", "image_models", on_delete: :cascade
  add_foreign_key "periods", "organizations", on_delete: :cascade
  add_foreign_key "plan_items", "business_units", on_delete: :cascade
  add_foreign_key "plan_items", "plans", on_delete: :cascade
  add_foreign_key "plans", "periods", on_delete: :cascade
  add_foreign_key "privileges", "roles", on_delete: :cascade
  add_foreign_key "process_controls", "best_practices", on_delete: :cascade
  add_foreign_key "repcat$_audit_column", "repcat$_audit_attribute", column: "attribute", primary_key: "attribute", name: "repcat$_audit_column_f1"
  add_foreign_key "repcat$_audit_column", "repcat$_conflict", column: "base_conflict_type_id", primary_key: "conflict_type_id", name: "repcat$_audit_column_f2"
  add_foreign_key "repcat$_audit_column", "repcat$_conflict", column: "base_oname", primary_key: "oname", name: "repcat$_audit_column_f2"
  add_foreign_key "repcat$_audit_column", "repcat$_conflict", column: "base_reference_name", primary_key: "reference_name", name: "repcat$_audit_column_f2"
  add_foreign_key "repcat$_audit_column", "repcat$_conflict", column: "base_sname", primary_key: "sname", name: "repcat$_audit_column_f2"
  add_foreign_key "repcat$_ddl", "repcat$_repcatlog", column: "log_id", name: "repcat$_ddl_prnt", on_delete: :cascade
  add_foreign_key "repcat$_ddl", "repcat$_repcatlog", column: "master", primary_key: "master", name: "repcat$_ddl_prnt", on_delete: :cascade
  add_foreign_key "repcat$_ddl", "repcat$_repcatlog", column: "role", primary_key: "role", name: "repcat$_ddl_prnt", on_delete: :cascade
  add_foreign_key "repcat$_ddl", "repcat$_repcatlog", column: "source", primary_key: "source", name: "repcat$_ddl_prnt", on_delete: :cascade
  add_foreign_key "repcat$_flavor_objects", "repcat$_flavors", column: "flavor_id", primary_key: "flavor_id", name: "repcat$_flavor_objects_fk2", on_delete: :cascade
  add_foreign_key "repcat$_flavor_objects", "repcat$_flavors", column: "gname", primary_key: "gname", name: "repcat$_flavor_objects_fk2", on_delete: :cascade
  add_foreign_key "repcat$_flavor_objects", "repcat$_flavors", column: "gowner", primary_key: "gowner", name: "repcat$_flavor_objects_fk2", on_delete: :cascade
  add_foreign_key "repcat$_flavor_objects", "repcat$_repcat", column: "gname", primary_key: "sname", name: "repcat$_flavor_objects_fk1", on_delete: :cascade
  add_foreign_key "repcat$_flavor_objects", "repcat$_repcat", column: "gowner", primary_key: "gowner", name: "repcat$_flavor_objects_fk1", on_delete: :cascade
  add_foreign_key "repcat$_flavors", "repcat$_repcat", column: "gname", primary_key: "sname", name: "repcat$_flavors_fk1", on_delete: :cascade
  add_foreign_key "repcat$_flavors", "repcat$_repcat", column: "gowner", primary_key: "gowner", name: "repcat$_flavors_fk1", on_delete: :cascade
  add_foreign_key "repcat$_generated", "repcat$_repobject", column: "base_oname", primary_key: "oname", name: "repcat$_repgen_prnt2", on_delete: :cascade
  add_foreign_key "repcat$_generated", "repcat$_repobject", column: "base_sname", primary_key: "sname", name: "repcat$_repgen_prnt2", on_delete: :cascade
  add_foreign_key "repcat$_generated", "repcat$_repobject", column: "base_type", primary_key: "type", name: "repcat$_repgen_prnt2", on_delete: :cascade
  add_foreign_key "repcat$_generated", "repcat$_repobject", column: "oname", primary_key: "oname", name: "repcat$_repgen_prnt", on_delete: :cascade
  add_foreign_key "repcat$_generated", "repcat$_repobject", column: "sname", primary_key: "sname", name: "repcat$_repgen_prnt", on_delete: :cascade
  add_foreign_key "repcat$_generated", "repcat$_repobject", column: "type", primary_key: "type", name: "repcat$_repgen_prnt", on_delete: :cascade
  add_foreign_key "repcat$_grouped_column", "repcat$_column_group", column: "group_name", primary_key: "group_name", name: "repcat$_grouped_column_f1"
  add_foreign_key "repcat$_grouped_column", "repcat$_column_group", column: "oname", primary_key: "oname", name: "repcat$_grouped_column_f1"
  add_foreign_key "repcat$_grouped_column", "repcat$_column_group", column: "sname", primary_key: "sname", name: "repcat$_grouped_column_f1"
  add_foreign_key "repcat$_instantiation_ddl", "repcat$_refresh_templates", column: "refresh_template_id", primary_key: "refresh_template_id", name: "repcat$_instantiation_ddl_fk1", on_delete: :cascade
  add_foreign_key "repcat$_key_columns", "repcat$_repobject", column: "oname", primary_key: "oname", name: "repcat$_key_columns_prnt", on_delete: :cascade
  add_foreign_key "repcat$_key_columns", "repcat$_repobject", column: "sname", primary_key: "sname", name: "repcat$_key_columns_prnt", on_delete: :cascade
  add_foreign_key "repcat$_key_columns", "repcat$_repobject", column: "type", primary_key: "type", name: "repcat$_key_columns_prnt", on_delete: :cascade
  add_foreign_key "repcat$_object_parms", "repcat$_template_objects", column: "template_object_id", primary_key: "template_object_id", name: "repcat$_object_parms_fk2", on_delete: :cascade
  add_foreign_key "repcat$_object_parms", "repcat$_template_parms", column: "template_parameter_id", primary_key: "template_parameter_id", name: "repcat$_object_parms_fk1"
  add_foreign_key "repcat$_parameter_column", "repcat$_resolution", column: "conflict_type_id", primary_key: "conflict_type_id", name: "repcat$_parameter_column_f1"
  add_foreign_key "repcat$_parameter_column", "repcat$_resolution", column: "oname", primary_key: "oname", name: "repcat$_parameter_column_f1"
  add_foreign_key "repcat$_parameter_column", "repcat$_resolution", column: "reference_name", primary_key: "reference_name", name: "repcat$_parameter_column_f1"
  add_foreign_key "repcat$_parameter_column", "repcat$_resolution", column: "sequence_no", primary_key: "sequence_no", name: "repcat$_parameter_column_f1"
  add_foreign_key "repcat$_parameter_column", "repcat$_resolution", column: "sname", primary_key: "sname", name: "repcat$_parameter_column_f1"
  add_foreign_key "repcat$_priority", "repcat$_priority_group", column: "priority_group", primary_key: "priority_group", name: "repcat$_priority_f1"
  add_foreign_key "repcat$_priority", "repcat$_priority_group", column: "sname", primary_key: "sname", name: "repcat$_priority_f1"
  add_foreign_key "repcat$_refresh_templates", "repcat$_template_status", column: "template_status_id", primary_key: "template_status_id", name: "repcat$_refresh_templates_fk2"
  add_foreign_key "repcat$_refresh_templates", "repcat$_template_types", column: "template_type_id", primary_key: "template_type_id", name: "repcat$_refresh_templates_fk1"
  add_foreign_key "repcat$_repcolumn", "repcat$_repobject", column: "oname", primary_key: "oname", name: "repcat$_repcolumn_fk", on_delete: :cascade
  add_foreign_key "repcat$_repcolumn", "repcat$_repobject", column: "sname", primary_key: "sname", name: "repcat$_repcolumn_fk", on_delete: :cascade
  add_foreign_key "repcat$_repcolumn", "repcat$_repobject", column: "type", primary_key: "type", name: "repcat$_repcolumn_fk", on_delete: :cascade
  add_foreign_key "repcat$_repgroup_privs", "repcat$_repcat", column: "gname", primary_key: "sname", name: "repcat$_repgroup_privs_fk", on_delete: :cascade
  add_foreign_key "repcat$_repgroup_privs", "repcat$_repcat", column: "gowner", primary_key: "gowner", name: "repcat$_repgroup_privs_fk", on_delete: :cascade
  add_foreign_key "repcat$_repobject", "repcat$_repcat", column: "gname", primary_key: "sname", name: "repcat$_repobject_prnt", on_delete: :cascade
  add_foreign_key "repcat$_repobject", "repcat$_repcat", column: "gowner", primary_key: "gowner", name: "repcat$_repobject_prnt", on_delete: :cascade
  add_foreign_key "repcat$_repprop", "repcat$_repobject", column: "oname", primary_key: "oname", name: "repcat$_repprop_prnt", on_delete: :cascade
  add_foreign_key "repcat$_repprop", "repcat$_repobject", column: "sname", primary_key: "sname", name: "repcat$_repprop_prnt", on_delete: :cascade
  add_foreign_key "repcat$_repprop", "repcat$_repobject", column: "type", primary_key: "type", name: "repcat$_repprop_prnt", on_delete: :cascade
  add_foreign_key "repcat$_repschema", "def$_destination", column: "dblink", primary_key: "dblink", name: "repcat$_repschema_dest"
  add_foreign_key "repcat$_repschema", "def$_destination", column: "extension_id", primary_key: "catchup", name: "repcat$_repschema_dest"
  add_foreign_key "repcat$_repschema", "repcat$_repcat", column: "gowner", primary_key: "gowner", name: "repcat$_repschema_prnt", on_delete: :cascade
  add_foreign_key "repcat$_repschema", "repcat$_repcat", column: "sname", primary_key: "sname", name: "repcat$_repschema_prnt", on_delete: :cascade
  add_foreign_key "repcat$_resolution", "repcat$_conflict", column: "conflict_type_id", primary_key: "conflict_type_id", name: "repcat$_resolution_f3"
  add_foreign_key "repcat$_resolution", "repcat$_conflict", column: "oname", primary_key: "oname", name: "repcat$_resolution_f3"
  add_foreign_key "repcat$_resolution", "repcat$_conflict", column: "reference_name", primary_key: "reference_name", name: "repcat$_resolution_f3"
  add_foreign_key "repcat$_resolution", "repcat$_conflict", column: "sname", primary_key: "sname", name: "repcat$_resolution_f3"
  add_foreign_key "repcat$_resolution", "repcat$_resolution_method", column: "conflict_type_id", primary_key: "conflict_type_id", name: "repcat$_resolution_f1"
  add_foreign_key "repcat$_resolution", "repcat$_resolution_method", column: "method_name", primary_key: "method_name", name: "repcat$_resolution_f1"
  add_foreign_key "repcat$_site_objects", "repcat$_object_types", column: "object_type_id", primary_key: "object_type_id", name: "repcat$_site_objects_fk1"
  add_foreign_key "repcat$_site_objects", "repcat$_template_sites", column: "template_site_id", primary_key: "template_site_id", name: "repcat$_site_object_fk2", on_delete: :cascade
  add_foreign_key "repcat$_sites_new", "repcat$_extension", column: "extension_id", primary_key: "extension_id", name: "repcat$_sites_new_fk1", on_delete: :cascade
  add_foreign_key "repcat$_sites_new", "repcat$_repcat", column: "gname", primary_key: "sname", name: "repcat$_sites_new_fk2", on_delete: :cascade
  add_foreign_key "repcat$_sites_new", "repcat$_repcat", column: "gowner", primary_key: "gowner", name: "repcat$_sites_new_fk2", on_delete: :cascade
  add_foreign_key "repcat$_template_objects", "repcat$_object_types", column: "object_type", primary_key: "object_type_id", name: "repcat$_template_objects_fk3"
  add_foreign_key "repcat$_template_objects", "repcat$_refresh_templates", column: "refresh_template_id", primary_key: "refresh_template_id", name: "repcat$_template_objects_fk1", on_delete: :cascade
  add_foreign_key "repcat$_template_parms", "repcat$_refresh_templates", column: "refresh_template_id", primary_key: "refresh_template_id", name: "repcat$_template_parms_fk1", on_delete: :cascade
  add_foreign_key "repcat$_template_refgroups", "repcat$_refresh_templates", column: "refresh_template_id", primary_key: "refresh_template_id", name: "repcat$_template_refgroups_fk1", on_delete: :cascade
  add_foreign_key "repcat$_user_authorizations", "repcat$_refresh_templates", column: "refresh_template_id", primary_key: "refresh_template_id", name: "repcat$_user_authorization_fk2", on_delete: :cascade
  add_foreign_key "repcat$_user_parm_values", "repcat$_template_parms", column: "template_parameter_id", primary_key: "template_parameter_id", name: "repcat$_user_parm_values_fk1", on_delete: :cascade
  add_foreign_key "resource_classes", "organizations", on_delete: :cascade
  add_foreign_key "resources", "resource_classes", on_delete: :cascade
  add_foreign_key "review_user_assignments", "reviews", on_delete: :cascade
  add_foreign_key "review_user_assignments", "users", on_delete: :cascade
  add_foreign_key "reviews", "file_models", on_delete: :cascade
  add_foreign_key "reviews", "periods", on_delete: :cascade
  add_foreign_key "reviews", "plan_items", on_delete: :cascade
  add_foreign_key "roles", "organizations", on_delete: :cascade
  add_foreign_key "settings", "organizations", on_delete: :cascade
  add_foreign_key "users", "resources", on_delete: :cascade
  add_foreign_key "users", "users", column: "manager_id", on_delete: :cascade
  add_foreign_key "work_papers", "file_models", on_delete: :cascade
  add_foreign_key "work_papers", "organizations", on_delete: :cascade
  add_foreign_key "workflow_items", "workflows", on_delete: :cascade
  add_foreign_key "workflows", "periods", on_delete: :cascade
  add_foreign_key "workflows", "reviews", on_delete: :cascade
  add_synonym "syscatalog", "sys.syscatalog", force: true
  add_synonym "catalog", "sys.catalog", force: true
  add_synonym "tab", "sys.tab", force: true
  add_synonym "col", "sys.col", force: true
  add_synonym "tabquotas", "sys.tabquotas", force: true
  add_synonym "sysfiles", "sys.sysfiles", force: true
  add_synonym "publicsyn", "sys.publicsyn", force: true
  add_synonym "product_user_profile", "system.sqlplus_product_profile", force: true

end
