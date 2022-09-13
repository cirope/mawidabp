require 'test_helper'

class FindingsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  setup do
    login
  end

  teardown do
    clear_current_attributes
  end

  test 'list incomplete findings' do
    incomplete_status_list = Finding::PENDING_STATUS -
                             [Finding::STATUS[:incomplete]]

    get :index, params: { completion_state: 'incomplete' }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| incomplete_status_list.include?(f.state) }
  end

  test 'list completed findings' do
    finding = findings(:being_implemented_weakness)
    completed_status_list = Finding::STATUS.values       -
                            Finding::PENDING_STATUS      -
                            [Finding::STATUS[:revoked]]  -
                            [Finding::STATUS[:repeated]]

    Current.user = users :supervisor

    finding.update! state: Finding::STATUS[:implemented_audited],
                    solution_date: Time.zone.today

    get :index, params: { completion_state: 'complete' }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| completed_status_list.include?(f.state) }
  end

  test 'list repeated findings' do
    finding = findings :unanswered_for_level_1_notification
    repeated_of = findings :being_implemented_weakness
    repeated_status_list = [Finding::STATUS[:repeated]]

    finding.update! repeated_of_id: repeated_of.id

    get :index, params: { completion_state: 'repeated' }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| repeated_status_list.include?(f.state) }
  end

  test 'list findings for follow_up_committee' do
    login user: users(:committee)

    get :index, params: { completion_state: 'incomplete' }

    assert_response :success
  end

  test 'list findings with search and sort' do
    get :index, params: {
      completion_state: 'incomplete',
      search: {
        query:   '1 2 4 y w',
        columns: ['title', 'review'],
        order:   'review'
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.review.identification.match /1 2 4/i }
  end

  test 'list findings sorted with search by date' do
    expected_count = USE_SCOPE_CYCLE ? 3 : 4

    get :index, params: {
      completion_state: 'incomplete',
      search: {
        query:   "> #{I18n.l(4.days.ago.to_date, format: :minimal)}",
        columns: ['review', 'issue_date']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal expected_count, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.review.conclusion_final_review.issue_date > 4.days.ago.to_date }
  end

  test 'list findings for user' do
    user = users :first_time

    get :index, params: {
      completion_state: 'incomplete',
      user_id:          user.id
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for users' do
    user = users :first_time

    get :index, params: {
      completion_state: 'incomplete',
      user_ids:         [user.id]
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for responsible auditor' do
    user = users :first_time

    get :index, params: {
      completion_state: 'incomplete',
      user_id:          user.id,
      as_responsible:   true
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for process owner' do
    user = users :audited

    login user: user

    get :index, params: {
      completion_state: 'incomplete',
      as_owner:         true
    }

    assert_response :success
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| f.finding_user_assignments.owners.map(&:user).include?(user) }
  end

  test 'list findings pending_to_endorsement' do
    finding            = findings :being_implemented_weakness
    new_finding_answer = FindingAnswer.new(answer: 'This date for me',
                                           commitment_date: Date.today.to_s(:db),
                                           user_id: users(:audited).id)

    finding.finding_answers << new_finding_answer

    new_finding_answer.reload

    new_finding_answer.endorsements << Endorsement.new(status: 'pending',
                                                       user_id: users(:supervisor).id)

    user = users :supervisor

    login user: user

    get :index, params: {
      completion_state:       'incomplete',
      pending_to_endorsement: true
    }

    assert_response :success
    assert assigns(:findings).any?
    assert assigns(:findings).all? do |f|
      f.finding_answers.any? { |f_a| f_a.endorsements.where(status: Endorsement.statuses['pending'], user_id: user.id).present? }
    end
  end

  test 'list findings for specific ids' do
    ids = [
      findings(:being_implemented_weakness).id,
      findings(:unconfirmed_for_notification_weakness).id
    ]

    get :index, params: {
      completion_state: 'incomplete',
      ids:              ids
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| ids.include?(f.id) }
  end

  test 'list findings as CSV' do
    get :index, params: { completion_state: 'incomplete' }, as: :csv

    assert_response :success
    assert_match Mime[:csv].to_s, @response.content_type
  end

  test 'list findings as PDF' do
    get :index, params: { completion_state: 'incomplete' }, as: :pdf

    assert_redirected_to /\/private\/.*\/findings\/.*\.pdf$/
    assert_match Mime[:pdf].to_s, @response.content_type
  end

  test 'list findings as corporate user' do
    organization = organizations :twitter

    login prefix: organization.prefix

    get :index, params: { completion_state: 'incomplete' }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert assigns(:findings).any? { |f| f.organization_id != organization.id }
  end

  test 'list findings and send CSV by email' do
    set_organization

    old_count = ::SEND_REPORT_EMAIL_AFTER_COUNT

    silence_warnings do
      ::SEND_REPORT_EMAIL_AFTER_COUNT = 10
    end

    perform_enqueued_jobs do
      get :index, params: { completion_state: 'incomplete' }, as: :csv
    end

    assert_redirected_to findings_url format: :csv, completion_state: 'incomplete'

    findings_count = assigns(:findings).to_a.size
    assert findings_count > 10

    filename = I18n.t('findings.index.title').downcase

    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
    attachment = ActionMailer::Base.deliveries.last.attachments.first
    assert_equal "#{filename}.zip", attachment.filename

    tmp_file = Tempfile.open do |temp|
      temp.binmode
      temp << attachment.read
      temp.path
    end

    csv_report = Zip::File.open(tmp_file, Zip::File::CREATE) do |zipfile|
      zipfile.read "#{filename}.csv"
    end

    # TODO: change to liberal_parsing: true when 2.3 support is dropped
    csv = CSV.parse csv_report[3..-1], col_sep: ';', force_quotes: true, headers: true

    assert_equal findings_count, csv.size

    silence_warnings { ::SEND_REPORT_EMAIL_AFTER_COUNT = old_count }
  end

  test 'show finding' do
    get :show, params: {
      completion_state: 'incomplete',
      id:               findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'show finding for follow_up_committee' do
    login user: users(:committee)

    get :show, params: {
      completion_state: 'incomplete',
      id:               findings(:being_implemented_oportunity)
    }

    assert_response :success
  end

  test 'edit finding as auditor' do
    login user: users(:auditor)

    get :edit, params: {
      completion_state: 'incomplete',
      id:               findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'edit finding as audited' do
    login user: users(:audited)

    get :edit, params: {
      completion_state: 'incomplete',
      id:               findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'unauthorized edit finding' do
    login user: users(:audited_second)

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completion_state: 'complete',
        id:               findings(:being_implemented_weakness_on_final)
      }
    end
  end

  test 'unauthorized edit of incomplete finding' do
    login user: users(:audited)

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completion_state: 'incomplete',
        id:               findings(:incomplete_weakness)
      }
    end
  end

  test 'edit implemented audited finding' do
    skip # Just for this customer
    finding = findings :being_implemented_weakness

    finding.update_columns state:         Finding::STATUS[:implemented_audited],
                           solution_date: Time.zone.today

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completion_state: 'complete',
        id:               finding
      }
    end
  end

  test 'update finding' do
    set_organization

    finding                 = findings :unconfirmed_weakness
    last_risk               = finding.risk
    last_risk_justification = finding.risk_justification

    login user: users(:supervisor)

    difference_counts = [
      'WorkPaper.count',
      'FindingAnswer.count',
      'Endorsement.count',
      'Cost.count',
      'FindingRelation.count',
      'Task.count',
      'BusinessUnitFinding.count',
      'Tagging.count'
    ]

    # One email on the answer, the other on the endorsement
    assert_enqueued_emails 2 do
      assert_difference difference_counts do
        assert_difference 'FileModel.count', 2 do
          patch :update, params: {
            completion_state: 'incomplete',
            id: finding,
            finding: {
              control_objective_item_id:
                control_objective_items(:impact_analysis_item_editable).id,
              review_code: 'O020',
              title: 'Title',
              description: 'Updated description',
              answer: 'Updated answer',
              current_situation: 'Updated current situation',
              current_situation_verified: '1',
              audit_comments: 'Updated audit comments',
              state: Finding::STATUS[:unconfirmed],
              origination_date: 1.day.ago.to_date.to_s(:db),
              audit_recommendations: 'Updated proposed action',
              effect: 'Updated effect',
              risk: Finding.risks_values.last,
              priority: Finding.priorities_values.last,
              compliance: 'no',
              operational_risk: ['internal fraud'],
              impact: ['econimic', 'regulatory'],
              internal_control_components: ['risk_evaluation', 'monitoring'],
              extension: false,
              manual_risk: (USE_SCOPE_CYCLE || Current.conclusion_pdf_format == 'bic' ? '0' : '1'),
              impact_risk: USE_SCOPE_CYCLE ? Finding.impact_risks[:critical] : (SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.impact_risks_bic[:high] : ''),
              probability: USE_SCOPE_CYCLE ? Finding.probabilities[:almost_certain] : (SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.frequencies[:high] : ''),
              state_regulations: SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.state_regulations[:not_exist] : '',
              degree_compliance: SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.degree_compliance[:fails] : '',
              observation_originated_tests: SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.observation_origination_tests[:design] : '',
              sample_deviation: SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.sample_deviation[:most_expected] : '',
              external_repeated: SHOW_CONCLUSION_ALTERNATIVE_PDF['cirope'] == 'bic' ? Finding.external_repeated[:repeated_without_action_plan] : '',
              business_unit_ids: [business_units(:business_unit_three).id],
              risk_justification: '',
              finding_user_assignments_attributes: [
                {
                  id: finding_user_assignments(:unconfirmed_weakness_audited).id,
                  user_id: users(:audited).id,
                  process_owner: '1'
                },
                {
                  id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
                  user_id: users(:auditor).id,
                  process_owner: ''
                },
                {
                  id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
                  user_id: users(:supervisor).id,
                  process_owner: ''
                }
              ],
              work_papers_attributes: [
                {
                  name: 'New workpaper name',
                  code: 'PTSO 20',
                  file_model_attributes: {
                    file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                  }
                }
              ],
              finding_answers_attributes: {
                '0' => {
                  answer: 'New answer',
                  user_id: users(:supervisor).id,
                  notify_users: '1',
                  file_model_attributes: {
                    file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                  },
                  endorsements_attributes: {
                    '0' => {
                      user_id: users(:administrator).id
                    }
                  }
                }
              },
              finding_relations_attributes: [
                {
                  description: 'Duplicated',
                  related_finding_id: findings(:unanswered_weakness).id
                }
              ],
              tasks_attributes: [
                {
                  code: '01',
                  description: 'New task',
                  status: 'pending',
                  due_on: I18n.l(Time.zone.tomorrow)
                }
              ],
              taggings_attributes: [
                {
                  id: taggings(:important_unconfirmed_weakness).id,
                  tag_id: tags(:important).id
                },
                {
                  id: taggings(:pending_unconfirmed_weakness).id,
                  tag_id: tags(:pending).id
                },
                {
                  tag_id: tags(:follow_up).id
                }
              ],
              costs_attributes: [
                {
                  cost: '12.5',
                  cost_type: 'audit',
                  description: 'New cost description',
                  user_id: users(:administrator).id
                }
              ]
            }
          }
        end
      end
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
    assert_equal 'Updated description', finding.reload.description
    assert_not_equal last_risk, finding.reload.risk
    assert_not_equal last_risk_justification, finding.reload.risk_justification
  end

  test 'update finding with audited user' do
    finding = findings :unconfirmed_weakness

    no_difference_count = [
      'WorkPaper.count',
      'FindingRelation.count'
    ]

    difference_count = [
      'FindingAnswer.count',
      'Cost.count',
      'FileModel.count'
    ]

    login user: users(:audited)

    assert_no_difference no_difference_count do
      assert_difference difference_count do
        patch :update, params: {
          completion_state: 'incomplete',
          id: finding,
          finding: {
            finding_answers_attributes: [
              {
                answer: 'New answer',
                commitment_date: I18n.l(Date.tomorrow),
                user_id: users(:audited).id,
                file_model_attributes: {
                  file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            ],
            costs_attributes: [
              {
                cost: '12.5',
                cost_type: 'audit',
                description: 'New cost description',
                user_id: users(:administrator).id
              }
            ]
          }
        }
      end
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
  end

  test 'update finding and notify to the new user' do
    finding = findings :unconfirmed_weakness

    login user: users(:supervisor)

    assert_enqueued_emails 1 do
      patch :update, params: {
        completion_state: 'incomplete',
        id: finding,
        finding: {
          control_objective_item_id: control_objective_items(:impact_analysis_item).id,
          review_code: 'O020',
          title: 'Title',
          description: 'Updated description',
          answer: 'Updated answer',
          current_situation: 'Updated current situation',
          current_situation_verified: '1',
          audit_comments: 'Updated audit comments',
          state: Finding::STATUS[:unconfirmed],
          origination_date: 1.day.ago.to_date.to_s(:db),
          audit_recommendations: 'Updated proposed action',
          effect: 'Updated effect',
          priority: Finding.priorities_values.first,
          compliance: 'no',
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          users_for_notification: [users(:bare).id],
          extension: false,
          finding_user_assignments_attributes: [
            {
              id: finding_user_assignments(:unconfirmed_weakness_bare).id,
              user_id: users(:bare).id,
              process_owner: ''
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_audited).id,
              user_id: users(:audited).id,
              process_owner: '1'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
              user_id: users(:auditor).id,
              process_owner: ''
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
              user_id: users(:supervisor).id,
              process_owner: ''
            }
          ]
        }
      }
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
    assert_equal 'Updated description', finding.reload.description
  end

  test 'update finding with tag_ids' do
    finding = findings :unconfirmed_weakness

    login user: users(:supervisor)

    assert_difference 'Tagging.count' do
      patch :update, params: {
        completion_state: 'incomplete',
        id: finding,
        finding: {
          control_objective_item_id: control_objective_items(:impact_analysis_item).id,
          review_code: 'O020',
          title: 'Title',
          description: 'Updated description',
          answer: 'Updated answer',
          current_situation: 'Updated current situation',
          current_situation_verified: '1',
          audit_comments: 'Updated audit comments',
          state: Finding::STATUS[:unconfirmed],
          origination_date: 1.day.ago.to_date.to_s(:db),
          audit_recommendations: 'Updated proposed action',
          effect: 'Updated effect',
          priority: Finding.priorities_values.first,
          compliance: 'no',
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          extension: false,
          tag_ids: [
            tags(:important).id,
            tags(:pending).id,
            tags(:follow_up).id
          ],
          finding_user_assignments_attributes: [
            {
              id: finding_user_assignments(:unconfirmed_weakness_audited).id,
              user_id: users(:audited).id,
              process_owner: '1'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
              user_id: users(:auditor).id,
              process_owner: ''
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
              user_id: users(:supervisor).id,
              process_owner: ''
            }
          ]
        }
      }
    end

    assert_redirected_to edit_finding_url('incomplete', finding)
    assert_equal 'Updated description', finding.reload.description
  end

  test 'auto complete for finding relation' do
    finding = findings :being_implemented_weakness_on_draft

    get :auto_complete_for_finding_relation, params: {
      completion_state: 'incomplete',
      q: 'O001',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    assert_equal 3, findings_response.size
    assert findings_response.all? { |f| (f['label'] + f['informal']).match /O001/i }
  end

  test 'auto complete for finding relation only between findings with final review' do
    finding = findings :unconfirmed_for_notification_weakness

    get :auto_complete_for_finding_relation, params: {
      completion_state: 'incomplete',
      q: 'O001',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    # Weakness O001 it's excluded since not belongs to a final review
    assert_equal 2, findings_response.size
    assert findings_response.all? { |f| (f['label'] + f['informal']).match /O001/i }
  end

  test 'auto complete for finding relation with multiple conditions' do
    finding = findings :unconfirmed_for_notification_weakness

    get :auto_complete_for_finding_relation, params: {
      completion_state: 'incomplete',
      q: 'O001; 1 2 3',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    # Just O001 from review 1 2 3
    assert_equal 1, findings_response.size
    assert findings_response.all? { |f| (f['label'] + f['informal']).match /O001.*1 2 3/i }
  end

  test 'auto complete for finding relation with empty results' do
    finding = findings :unconfirmed_for_notification_weakness

    get :auto_complete_for_finding_relation, params: {
      completion_state: 'incomplete',
      q: 'x_none',
      finding_id: finding.id,
      review_id: finding.review.id
    }, as: :json

    assert_response :success

    findings_response = ActiveSupport::JSON.decode @response.body

    assert_equal 0, findings_response.size
  end

  test 'auto complete for tagging' do
    get :auto_complete_for_tagging, params: {
      q: 'impor',
      completion_state: 'incomplete',
      kind: 'finding'
    }, as: :json

    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 1, tags.size
    assert tags.all? { |t| t['label'].match /impor/i }
  end

  test 'auto complete for tagging with empty results' do
    get :auto_complete_for_tagging, params: {
      q: 'x_none',
      completion_state: 'incomplete',
      kind: 'finding'
    }, as: :json

    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, tags.size
  end

  test 'auto complete for obsolete tagging should yield empty results' do
    tag = tags :important

    tag.update! obsolete: true

    get :auto_complete_for_tagging, params: {
      q: 'impor',
      completion_state: 'incomplete',
      kind: 'finding'
    }, as: :json

    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, tags.size
  end

  test 'check order by not readed comments desc' do
    skip unless POSTGRESQL_ADAPTER

    # we already have a test that checks the response
    get :index, params: { completion_state: 'incomplete' }

    first = findings(:unanswered_for_level_1_notification)
    second = findings(:unanswered_for_level_2_notification)

    # ensure first two elements are different than chosen
    assert_empty(assigns(:findings).first(2).map(&:id) & [first.id, second.id])

    # First place
    3.times { create_finding_answers_for(first, destroy_readings: true) }
    # Second place
    create_finding_answers_for(second, destroy_readings: true)

    get :index, params: {
      completion_state: 'incomplete',
      search: {
        order: 'readings_desc'
      }
    }
    assert_response :success

    ordered_findings = assigns(:findings)
    assert_equal first.id, ordered_findings.first.id
    assert_equal second.id, ordered_findings.second.id
  end

  test 'check order by not readed comments desc in all formats' do
    skip unless POSTGRESQL_ADAPTER

    first = findings(:unanswered_for_level_1_notification)
    second = findings(:unanswered_for_level_2_notification)

    3.times { create_finding_answers_for(first, destroy_readings: true) }
    create_finding_answers_for(second, destroy_readings: true)

    get :index, params: {
      completion_state: 'incomplete',
      search: {
        order: 'readings_desc'
      }
    }
    assert_response :success
    html_findings = assigns(:findings).pluck(:id)

    get :index, params: {
      completion_state: 'incomplete',
      search: {
        order: 'readings_desc'
      }
    }, as: :csv
    assert_response :success
    # forcing quote_char because of the html response
    csv = CSV.parse(@response.body, col_sep: ';', quote_char: "'", headers: true)
    csv_findings = []
    csv.each do |row|
      id = row['"Id"'].strip.tr('"', '').to_i
      csv_findings << id if id&.positive?
    end

    get :index, params: {
      completion_state: 'incomplete',
      search: {
        order: 'readings_desc'
      }
    }, as: :pdf
    # we can't check the order inside the PDF so...
    assert_redirected_to /\/private\/.*\/findings\/.*\.pdf$/

    assert_equal(
      html_findings,
      csv_findings[0...html_findings.size] # csv is not paginated
    )
  end

  test 'list findings with search by updated_at' do
    get :index, params: {
      completion_state: 'incomplete',
      search: {
        query:   "> #{I18n.l(4.days.ago.to_date, format: :minimal)}",
        columns: ['updated_at']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_not_empty assigns(:findings)
    assert assigns(:findings).all? { |f| f.updated_at > 4.days.ago.to_date }

    get :index, params: {
      completion_state: 'incomplete',
      search: {
        query:   "< #{I18n.l(2.days.ago.to_date, format: :minimal)}",
        columns: ['updated_at']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_empty assigns(:findings)
  end

  test 'assert exception when not bic pdf format and get edit bic sigen fields' do
    skip_if_bic_include_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    assert_raise ActiveRecord::RecordNotFound do
      get :edit_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id
      }
    end
  end

  test 'assert exception when finding is pending and get edit bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    assert_raise ActiveRecord::RecordNotFound do
      get :edit_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: findings(:being_implemented_weakness).id
      }
    end
  end

  test 'assert exception when finding is repeated and get edit bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    finding       = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:repeated]

    finding.save!

    assert_raise ActiveRecord::RecordNotFound do
      get :edit_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id
      }
    end
  end

  test 'assert exception when user is can act as audited, exclude in finding and get edit bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    user_in_finding = finding_user_assignments :being_implemented_weakness_administrator

    user_in_finding.destroy

    assert_raise ActiveRecord::RecordNotFound do
      get :edit_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id
      }
    end
  end

  test 'assert response get edit bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)

    finding.save!

    assert_nothing_raised do
      get :edit_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id
      }
    end
    assert_response :success
  end

  test 'assert exception when not bic pdf format and update bic sigen fields' do
    skip_if_bic_include_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)
    work_paper            = work_papers :text_work_paper_being_implemented_weakness

    finding.save!

    work_paper.destroy

    assert_raise ActiveRecord::RecordNotFound do
      get :update_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id,
        finding: {
          year: '2022',
          nsisio: '1234',
          nobs: '9876',
          skip_work_paper: '1'
        }
      }
    end
  end

  test 'assert exception when finding is pending and update bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    work_paper = work_papers :text_work_paper_being_implemented_weakness

    work_paper.destroy

    assert_raise ActiveRecord::RecordNotFound do
      get :update_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: findings(:being_implemented_weakness).id,
        finding: {
          year: '2022',
          nsisio: '1234',
          nobs: '9876',
          skip_work_paper: '1'
        }
      }
    end
  end

  test 'assert exception when finding is repeated and update bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    finding       = findings :being_implemented_weakness
    finding.state = Finding::STATUS[:repeated]
    work_paper    = work_papers :text_work_paper_being_implemented_weakness

    finding.save!

    work_paper.destroy

    assert_raise ActiveRecord::RecordNotFound do
      get :update_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id,
        finding: {
          year: '2022',
          nsisio: '1234',
          nobs: '9876',
          skip_work_paper: '1'
        }
      }
    end
  end

  test 'assert exception when user is can act as audited, exclude in finding and update bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)
    work_paper            = work_papers :text_work_paper_being_implemented_weakness

    finding.save!

    user_in_finding = finding_user_assignments :being_implemented_weakness_administrator

    user_in_finding.destroy

    work_paper.destroy

    assert_raise ActiveRecord::RecordNotFound do
      get :update_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id,
        finding: {
          year: '2022',
          nsisio: '1234',
          nobs: '9876',
          skip_work_paper: '1'
        }
      }
    end
  end

  test 'not update bic sigen fields when not send skip work paper' do
    skip_if_bic_exclude_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)
    work_paper            = work_papers :text_work_paper_being_implemented_weakness

    finding.save!

    work_paper.destroy

    get :update_bic_sigen_fields, params: {
      completion_state: 'complete',
      id: finding.id,
      finding: {
        year: '2022',
        nsisio: '1234',
        nobs: '9876'
      }
    }

    assert_match I18n.t('activerecord.errors.models.finding.attributes.state.must_have_a_work_paper'), 
                 response.body

    finding.reload

    assert_not_equal '2022', finding.year
    assert_not_equal '1234', finding.nsisio
    assert_not_equal '9876', finding.nobs
  end

  test 'assert response update bic sigen fields' do
    skip_if_bic_exclude_in_current_pdf_format

    Current.user          = users :supervisor
    finding               = findings :being_implemented_weakness
    finding.state         = Finding::STATUS[:implemented_audited]
    finding.solution_date = Date.today.to_s(:db)
    work_paper            = work_papers :text_work_paper_being_implemented_weakness

    finding.save!

    work_paper.destroy

    assert_nothing_raised do
      get :update_bic_sigen_fields, params: {
        completion_state: 'complete',
        id: finding.id,
        finding: {
          year: '2022',
          nsisio: '1234',
          nobs: '9876',
          skip_work_paper: '1'
        }
      }
    end

    assert_response :redirect
    assert_equal I18n.t('finding.correctly_updated'), flash[:notice]
    assert_redirected_to edit_bic_sigen_fields_finding_path('complete', finding)

    finding.reload

    assert_equal '2022', finding.year
    assert_equal '1234', finding.nsisio
    assert_equal '9876', finding.nobs
  end

  private

    def create_finding_answers_for(finding, destroy_readings: false)
      finding_answer = finding.finding_answers.create!(
        answer: 'something',
        user_id: users(:administrator).id,
        commitment_date: 1.day.from_now
      )
      finding_answer.readings.map(&:destroy!) if destroy_readings
      finding_answer
    end

    def repeated_status_list
      [Finding::STATUS[:repeated]]
    end

    def skip_if_bic_include_in_current_pdf_format
      set_organization

      skip if %w(bic).include?(Current.conclusion_pdf_format)
    end

    def skip_if_bic_exclude_in_current_pdf_format
      set_organization

      skip if %w(bic).exclude?(Current.conclusion_pdf_format)
    end
end
