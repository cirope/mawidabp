require 'test_helper'

class FindingsControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper
  include ActiveJob::TestHelper

  setup do
    login
  end

  test 'list findings' do
    get :index, params: { completed: 'incomplete' }

    assert_response :success
  end

  test 'list findings for follow_up_committee' do
    login user: users(:committee)

    get :index, params: { completed: 'incomplete' }

    assert_response :success
  end

  test 'list findings with search and sort' do
    get :index, params: {
      completed: 'incomplete',
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
    get :index, params: {
      completed: 'incomplete',
      search: {
        query:   "> #{I18n.l(4.days.ago.to_date, format: :minimal)}",
        columns: ['review', 'issue_date']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 4, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.review.conclusion_final_review.issue_date > 4.days.ago.to_date }
  end

  test 'list findings for user' do
    user = users :first_time

    get :index, params: {
      completed: 'incomplete',
      user_id:   user.id
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for users' do
    user = users :first_time

    get :index, params: {
      completed: 'incomplete',
      user_ids:  [user.id]
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for responsible auditor' do
    user = users :first_time

    get :index, params: {
      completed:      'incomplete',
      user_id:        user.id,
      as_responsible: true
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 1, assigns(:findings).count
    assert assigns(:findings).all? { |f| f.users.include?(user) }
  end

  test 'list findings for process owner' do
    user = users :audited

    login user: user

    get :index, params: {
      completed: 'incomplete',
      as_owner:  true
    }

    assert_response :success
    assert assigns(:findings).any?
    assert assigns(:findings).all? { |f| f.finding_user_assignments.owners.map(&:user).include?(user) }
  end

  test 'list findings for specific ids' do
    ids = [
      findings(:being_implemented_weakness).id,
      findings(:unconfirmed_for_notification_weakness).id
    ]

    get :index, params: {
      completed: 'incomplete',
      ids:       ids
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_equal 2, assigns(:findings).count
    assert assigns(:findings).all? { |f| ids.include?(f.id) }
  end

  test 'list findings as CSV' do
    get :index, params: { completed: 'incomplete' }, as: :csv

    assert_response :success
    assert_equal "#{Mime[:csv]}", @response.content_type
  end

  test 'list findings as PDF' do
    get :index, params: { completed: 'incomplete' }, as: :pdf

    assert_redirected_to /\/private\/.*\/findings\/.*\.pdf$/
    assert_equal "#{Mime[:pdf]}", @response.content_type
  end

  test 'list findings as corporate user' do
    organization = organizations :twitter

    login prefix: organization.prefix

    get :index, params: { completed: 'incomplete' }

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
      get :index, params: { completed: 'incomplete' }, as: :csv
    end

    assert_redirected_to findings_url format: :csv, completed: 'incomplete'

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

    csv = CSV.parse csv_report, col_sep: ';', force_quotes: true, headers: true, liberal_parsing: true

    assert_equal findings_count, csv.size

    silence_warnings { ::SEND_REPORT_EMAIL_AFTER_COUNT = old_count }
  end

  test 'show finding' do
    get :show, params: {
      completed: 'incomplete',
      id:        findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'show finding for follow_up_committee' do
    login user: users(:committee)

    get :show, params: {
      completed: 'incomplete',
      id:        findings(:being_implemented_oportunity)
    }

    assert_response :success
  end

  test 'edit finding as auditor' do
    login user: users(:auditor)

    get :edit, params: {
      completed: 'incomplete',
      id:        findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'edit finding as audited' do
    login user: users(:audited)

    get :edit, params: {
      completed: 'incomplete',
      id:        findings(:unanswered_weakness)
    }

    assert_response :success
  end

  test 'unauthorized edit finding' do
    login user: users(:audited_second)

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completed: 'complete',
        id:        findings(:being_implemented_weakness_on_final)
      }
    end
  end

  test 'unauthorized edit of incomplete finding' do
    login user: users(:audited)

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completed: 'incomplete',
        id:        findings(:incomplete_weakness)
      }
    end
  end

  test 'edit implemented audited finding' do
    finding = findings :being_implemented_weakness

    finding.update_column :state, Finding::STATUS[:implemented_audited]

    assert_raise ActiveRecord::RecordNotFound do
      get :edit, params: {
        completed: 'complete',
        id:        finding
      }
    end
  end

  test 'update finding' do
    finding = findings :unconfirmed_weakness

    login user: users(:supervisor)

    difference_counts = [
      'WorkPaper.count',
      'FindingAnswer.count',
      'Cost.count',
      'FindingRelation.count',
      'Task.count',
      'BusinessUnitFinding.count',
      'Tagging.count'
    ]

    assert_enqueued_emails 1 do
      assert_difference difference_counts do
        assert_difference 'FileModel.count', 2 do
          patch :update, params: {
            completed: 'incomplete',
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
              risk: Finding.risks_values.first,
              priority: Finding.priorities_values.first,
              compliance: 'no',
              operational_risk: ['internal fraud'],
              impact: ['econimic', 'regulatory'],
              internal_control_components: ['risk_evaluation', 'monitoring'],
              business_unit_ids: [business_units(:business_unit_three).id],
              finding_user_assignments_attributes: [
                {
                  id: finding_user_assignments(:unconfirmed_weakness_audited).id,
                  user_id: users(:audited).id,
                  process_owner: '1'
                },
                {
                  id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
                  user_id: users(:auditor).id,
                  process_owner: '0'
                },
                {
                  id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
                  user_id: users(:supervisor).id,
                  process_owner: '0'
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
              finding_answers_attributes: [
                {
                  answer: 'New answer',
                  user_id: users(:supervisor).id,
                  notify_users: '1',
                  file_model_attributes: {
                    file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
                  }
                }
              ],
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
          completed: 'incomplete',
          id: finding,
          finding: {
            control_objective_item_id: control_objective_items(:impact_analysis_item_editable).id,
            review_code: 'O020',
            title: 'Title',
            description: 'Updated description',
            answer: 'Updated answer',
            current_situation: 'Updated current situation',
            current_situation_verified: '1',
            audit_comments: 'Updated audit comments',
            state: Finding::STATUS[:unconfirmed],
            origination_date: 35.day.ago.to_date.to_s(:db),
            solution_date: 31.days.from_now.to_date,
            audit_recommendations: 'Updated proposed action',
            effect: 'Updated effect',
            risk: Finding.risks_values.first,
            priority: Finding.priorities_values.first,
            follow_up_date: 3.days.from_now.to_date,
            compliance: 'no',
            operational_risk: ['internal fraud'],
            impact: ['econimic', 'regulatory'],
            internal_control_components: ['risk_evaluation', 'monitoring'],
            finding_user_assignments_attributes: [
              {
                user_id: users(:audited).id,
                process_owner: '1'
              },
              {
                user_id: users(:auditor).id,
                process_owner: '0'
              },
              {
                user_id: users(:supervisor).id,
                process_owner: '0'
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
            finding_relations_attributes: [
              {
                description: 'Duplicated',
                related_finding_id: findings(:unanswered_weakness).id
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
    assert_not_equal 'Updated description', finding.reload.description
  end

  test 'update finding and notify to the new user' do
    finding = findings :unconfirmed_weakness

    login user: users(:supervisor)

    assert_enqueued_emails 1 do
      patch :update, params: {
        completed: 'incomplete',
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
          risk: Finding.risks_values.first,
          priority: Finding.priorities_values.first,
          compliance: 'no',
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
          users_for_notification: [users(:bare).id],
          finding_user_assignments_attributes: [
            {
              id: finding_user_assignments(:unconfirmed_weakness_bare).id,
              user_id: users(:bare).id,
              process_owner: '0'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_audited).id,
              user_id: users(:audited).id,
              process_owner: '1'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_auditor).id,
              user_id: users(:auditor).id,
              process_owner: '0'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
              user_id: users(:supervisor).id,
              process_owner: '0'
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
        completed: 'incomplete',
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
          risk: Finding.risks_values.first,
          priority: Finding.priorities_values.first,
          compliance: 'no',
          operational_risk: ['internal fraud'],
          impact: ['econimic', 'regulatory'],
          internal_control_components: ['risk_evaluation', 'monitoring'],
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
              process_owner: '0'
            },
            {
              id: finding_user_assignments(:unconfirmed_weakness_supervisor).id,
              user_id: users(:supervisor).id,
              process_owner: '0'
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
      completed: 'incomplete',
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
      completed: 'incomplete',
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
      completed: 'incomplete',
      q: 'O001, 1 2 3',
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
      completed: 'incomplete',
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
      completed: 'incomplete',
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
      completed: 'incomplete',
      kind: 'finding'
    }, as: :json

    assert_response :success

    tags = ActiveSupport::JSON.decode @response.body

    assert_equal 0, tags.size
  end

  test 'check order by not readed comments desc' do
    skip unless POSTGRESQL_ADAPTER

    # we already have a test that checks the response
    get :index, params: { completed: 'incomplete' }

    first = findings(:unanswered_for_level_1_notification)
    second = findings(:unanswered_for_level_2_notification)

    # ensure first two elements are different than chosen
    assert_empty(assigns(:findings).first(2).map(&:id) & [first.id, second.id])

    # First place
    3.times { create_finding_answers_for(first, destroy_readings: true) }
    # Second place
    create_finding_answers_for(second, destroy_readings: true)

    get :index, params: {
      completed: 'incomplete',
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
      completed: 'incomplete',
      search: {
        order: 'readings_desc'
      }
    }
    assert_response :success
    html_findings = assigns(:findings).pluck(:id)

    get :index, params: {
      completed: 'incomplete',
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
      completed: 'incomplete',
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
      completed: 'incomplete',
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
      completed: 'incomplete',
      search: {
        query:   "< #{I18n.l(2.days.ago.to_date, format: :minimal)}",
        columns: ['updated_at']
      }
    }

    assert_response :success
    assert_not_nil assigns(:findings)
    assert_empty assigns(:findings)
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
end
