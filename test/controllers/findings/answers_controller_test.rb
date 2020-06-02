require 'test_helper'

class Findings::AnswersControllerTest < ActionController::TestCase
  include ActionMailer::TestHelper

  setup do
    @finding = findings :unconfirmed_weakness

    login
  end

  test 'create finding answer' do
    assert_enqueued_emails 1 do
      assert_difference '@finding.finding_answers.count' do
        post :create, params: {
          finding_id:       @finding.id,
          completion_state: 'incomplete',
          finding_answer:   {
            answer:                 'New answer',
            user_id:                users(:supervisor).id,
            notify_users:           '1',
            file_model_attributes: {
              file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
            }
          }
        }
      end
    end

    assert_redirected_to finding_url('incomplete', @finding)
  end

  test 'update finding answer endorsement' do
    user           = users :administrator
    finding        = findings :being_implemented_weakness_on_draft
    finding_answer = finding.finding_answers.create!(
      answer: 'Test answer',
      user:   user
    )

    endorsement = finding_answer.endorsements.create! user: user

    assert endorsement.pending?

    patch :update, params: {
      id:               finding_answer.id,
      finding_id:       finding.id,
      completion_state: 'incomplete',
      approve:          true,
      reason:           'Should be fine'
    }, xhr: true, as: :js

    assert endorsement.reload.approved?
    assert_match Mime[:js].to_s, @response.content_type
  end
end
