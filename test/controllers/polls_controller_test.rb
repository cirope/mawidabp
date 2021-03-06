require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  setup do
    @poll = polls(:poll_one)

    login
  end

  test 'list polls' do
    get :index
    assert_response :success
    assert_not_nil assigns(:polls)
    assert_template 'polls/index'
  end

  test 'list reports' do
    get :reports
    assert_response :success
    assert_not_nil assigns(:title)
    assert_template 'polls/reports'
  end

  test 'show poll' do
    get :show, params: { id: @poll }
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_template 'polls/show'
  end

  test 'new poll' do
    get :new
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_template 'polls/new'
  end

  test 'create poll' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries = []

    assert_difference ['Poll.count', 'ActionMailer::Base.deliveries.count'] do
      assert_difference 'Answer.count', 2 do
        post :create, params: {
          poll: {
            user_id: users(:administrator).id,
            questionnaire_id: questionnaires(:questionnaire_one).id,
            answers_attributes: [
              {
                answer: 'Answer',
                comments: 'Comments',
                type: 'AnswerWritten'
              }, {
                answer_option_id: answer_options(:strongly_agree).id,
                type: 'AnswerMultiChoice'
              }
            ]
          }
        }
      end
    end
    assert_redirected_to poll_path(assigns(:poll))
  end

  test 'create poll about a business unit' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries = []

    about = business_units(:business_unit_one)
    assert_difference ['Poll.count', 'ActionMailer::Base.deliveries.count'] do
      post :create, params: {
        poll: {
          user_id:          users(:administrator).id,
          questionnaire_id: questionnaires(:questionnaire_one).id,
          about_id:         about.id,
          about_type:       about.class.name
        }
      }
    end

    assert_equal about.id, assigns(:poll).about_id
    assert_equal about.class.name, assigns(:poll).about_type
    assert_redirected_to poll_path(assigns(:poll))
  end

  test 'create poll about a (non) business unit' do
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries = []

    about = business_unit_types(:cycle)
    assert_no_difference ['Poll.count', 'ActionMailer::Base.deliveries.count'] do
      post :create, params: {
        poll: {
          user_id:          users(:administrator).id,
          questionnaire_id: questionnaires(:questionnaire_one).id,
          about_id:         about.id,
          about_type:       ''
        }
      }
    end

    # Error
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_template 'polls/new'
  end

  test 'edit poll' do
    set_host_for_organization(@poll.organization.prefix)

    get :edit, params: {
      id: @poll,
      token: @poll.access_token
    }
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_template 'polls/edit'
  end

  test 'update poll' do
    set_host_for_organization(@poll.organization.prefix)

    assert_no_difference ['Poll.count', 'Answer.count'] do
      patch :update, params: {
        id: @poll,
        poll: {
          user_id: users(:administrator).id,
          questionnaire_id: questionnaires(:questionnaire_one).id,
          comments: 'Encuesta actualizada',
          answers_attributes: [
            {
              id: answers(:answer_written).id,
              answer: 'Answer',
              comments: 'Comments',
              type: 'AnswerWritten'
            }, {
              id: answers(:answer_multi_choice).id,
              answer_option_id: answer_options(:strongly_agree).id,
              type: 'AnswerMultiChoice'
            }
          ]
        }
      }
    end

    assert_redirected_to poll_url(@poll)
    assert_not_nil assigns(:poll)
    assert_equal 'Encuesta actualizada', assigns(:poll).comments
    assert_equal true, assigns(:poll).answered
  end

  test 'destroy poll' do
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -@poll.answers.count do
        delete :destroy, params: { id: @poll }
      end
    end

    assert_redirected_to polls_url
  end
end
