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
          finding_id:     @finding.id,
          completed:      'incomplete',
          finding_answer: {
            answer:                 'New answer',
            user_id:                users(:supervisor).id,
            notify_users:           '1',
            file_model_attributes:  {
              file: Rack::Test::UploadedFile.new(TEST_FILE_FULL_PATH, 'text/plain')
            }
          }
        }
      end
    end

    assert_redirected_to finding_url('incomplete', @finding)
  end
end
