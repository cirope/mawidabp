require 'test_helper'

class PollsControllerTest < ActionController::TestCase
  test 'public and private actions' do
    poll = polls(:poll_one)
    @request.host = "#{poll.organization.prefix}.localhost.i"

    id_token = { id: poll.to_param, token: poll.access_token }
    id_param = {id: poll.to_param}
    public_actions = [
      [:get, :edit, id_token],
      [:get, :show, id_param],
      [:patch, :update, id_param.merge(poll: id_param)],
    ]
    private_actions = [
      [:get, :index],
      [:get, :new],
      [:get, :import_csv_customers],
      [:get, :summary_by_questionnaire],
      [:get, :summary_by_answers],
      [:get, :summary_by_business_unit],
      [:get, :create_summary_by_questionnaire],
      [:get, :create_summary_by_business_unit],
      [:get, :create_summary_by_answers],
      [:post, :send_csv_polls],
      [:post, :create],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      if action.include? :update
        assert_response :redirect
      else
        assert_response :success
      end
    end
  end

  test 'list polls' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:polls)
    assert_select '#error_body', false
    assert_template 'polls/index'
  end

  test 'list reports' do
    perform_auth
    get :reports
    assert_response :success
    assert_not_nil assigns(:title)
    assert_select '#error_body', false
    assert_template 'polls/reports'
  end

  test 'show poll' do
    perform_auth
    get :show, id: polls(:poll_one).id
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/show'
  end

  test 'new poll' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/new'
  end

  test 'create poll' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries = []

    assert_difference ['Poll.count', 'ActionMailer::Base.deliveries.count'] do
      assert_difference 'Answer.count', 2 do
        post :create, {
          poll: {
            user_id: users(:administrator_user).id,
            questionnaire_id: questionnaires(:questionnaire_one).id,
            answers_attributes: [
              {
                answer: 'Answer',
                comments: 'Comments',
                type: 'AnswerWritten'
              }, {
                answer_option_id: answer_options(:ao1).id,
                type: 'AnswerMultiChoice'
              }
            ]
          }
        }
      end
    end
    assert_redirected_to poll_path(assigns(:poll))
  end

  test 'edit poll' do
    poll = polls(:poll_one)
    @request.host = "#{poll.organization.prefix}.localhost.i"

    get :edit, id: poll.id, token: poll.access_token
    assert_response :success
    assert_not_nil assigns(:poll)
    assert_select '#error_body', false
    assert_template 'polls/edit'
  end

  test 'update poll' do
    poll = polls(:poll_one)
    @request.host = "#{poll.organization.prefix}.localhost.i"

    assert_no_difference ['Poll.count', 'Answer.count'] do
      patch :update, {
        id: poll.id,
        poll: {
          user_id: users(:administrator_user).id,
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
              answer_option_id: answer_options(:ao1).id,
              type: 'AnswerMultiChoice'
            }
          ]
        }
      }
    end

    assert_redirected_to poll_url(polls(:poll_one), layout: 'application_clean')
    assert_not_nil assigns(:poll)
    assert_equal 'Encuesta actualizada', assigns(:poll).comments
    assert_equal true, assigns(:poll).answered
  end

  test 'destroy poll' do
    perform_auth
    assert_difference 'Poll.count', -1 do
      assert_difference 'Answer.count', -2 do
        delete :destroy, id: polls(:poll_one).id
      end
    end

    assert_redirected_to polls_url
  end

  test 'summary by questionnaire' do
    perform_auth

    get :summary_by_questionnaire
    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_questionnaire'

    assert_nothing_raised(Exception) do
      get :summary_by_questionnaire, summary_by_questionnaire: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date,
        questionnaire: questionnaires(:questionnaire_one).id
      }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_questionnaire'
  end

  test 'filtered questionnaire report' do
    perform_auth
    get :summary_by_questionnaire, summary_by_questionnaire: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date,
      questionnaire: questionnaires(:questionnaire_one).id
    }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:questionnaire)
    assert_not_nil assigns(:polls)
    assert_not_nil assigns(:answered)
    assert_not_nil assigns(:unanswered)
    assert_not_nil assigns(:rates)
    assert_template 'polls/summary_by_questionnaire'
  end

  test 'create summary by questionnaire' do
    perform_auth

    post :create_summary_by_questionnaire, summary_by_questionnaire: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date,
      questionnaire: questionnaires(:questionnaire_one).id
    },
      report_title: 'New title',
      report_subtitle: 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(I18n.t('poll.summary_pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)), 'summary_by_questionnaire', 0)
  end

  test 'summary by business_unit' do
    perform_auth

    get :summary_by_business_unit
    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_business_unit'

    assert_nothing_raised(Exception) do
      get :summary_by_business_unit, summary_by_business_unit: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date,
        questionnaire: questionnaires(:questionnaire_one).id,
        business_unit_type: business_unit_types(:cycle).id
      }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_business_unit'
  end

  test 'filtered business unit report' do
    perform_auth
    get :summary_by_business_unit, summary_by_business_unit: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date,
      questionnaire: questionnaires(:questionnaire_one).id,
      business_unit_type: business_unit_types(:cycle).id
    }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:questionnaire)
    assert_not_nil assigns(:questionnaires)
    assert_not_nil assigns(:from_date)
    assert_not_nil assigns(:to_date)
    assert_not_nil assigns(:business_unit_polls)
    assert_not_nil assigns(:selected_business_unit)
    assert_template 'polls/summary_by_business_unit'
  end

  test 'create summary by business unit' do
    perform_auth

    post :create_summary_by_business_unit, summary_by_business_unit: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date,
      questionnaire: questionnaires(:questionnaire_one).id,
      business_unit_type: business_unit_types(:cycle).id
    },
      report_title: 'New title',
      report_subtitle: 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(I18n.t('poll.summary_pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)), 'summary_by_business_unit', 0)
  end


  test 'summary by answers' do
    perform_auth

    get :summary_by_answers
    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_answers'

    assert_nothing_raised(Exception) do
      get :summary_by_answers, summary_by_answers: {
        from_date: 10.years.ago.to_date,
        to_date: 10.years.from_now.to_date,
        questionnaire: questionnaires(:questionnaire_one).id,
        answered: 'true'
      }
    end

    assert_response :success
    assert_select '#error_body', false
    assert_template 'polls/summary_by_answers'
  end

  test 'filtered answers report' do
    perform_auth
    get :summary_by_answers, summary_by_answers: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date,
      questionnaire: questionnaires(:questionnaire_one).id,
      answered: nil
    }

    assert_response :success
    assert_select '#error_body', false
    assert_not_nil assigns(:questionnaire)
    assert_not_nil assigns(:polls)
    assert_not_nil assigns(:answered)
    assert_not_nil assigns(:unanswered)
    assert_template 'polls/summary_by_answers'
  end

  test 'create summary by answers' do
    perform_auth

    post :create_summary_by_answers, summary_by_answers: {
      from_date: 10.years.ago.to_date,
      to_date: 10.years.from_now.to_date,
      questionnaire: questionnaires(:questionnaire_one).id,
      answered: 'false'
    },
      report_title: 'New title',
      report_subtitle: 'New subtitle'

    assert_redirected_to Prawn::Document.relative_path(I18n.t('poll.summary_pdf_name',
        from_date: 10.years.ago.to_date.to_formatted_s(:db),
        to_date: 10.years.from_now.to_date.to_formatted_s(:db)), 'summary_by_answers', 0)
  end

  test 'send csv polls' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.deliveries = []

    assert_difference ['Poll.count', 'ActionMailer::Base.deliveries.count'], 2 do
      assert_difference 'Answer.count', 4 do
        post :send_csv_polls, dump_emails: {
          file: fixture_file_upload('files/customer_emails.csv', 'text/csv'),
          questionnaire_id: questionnaires(:questionnaire_one).id
        }
      end
    end

    assert_redirected_to polls_path
    assert_equal I18n.t('poll.customer_polls_sended', count: 2), flash[:notice]

    assert_no_difference 'Poll.count' do
      post :send_csv_polls, dump_emails: {}

      assert_response :success
    end

    # Prueba adjuntar un archivo que no sea csv
    assert_no_difference('Poll.count') do
      post :send_csv_polls, dump_emails: {
        file: fixture_file_upload('files/customer_emails.txt', 'text/csv')
      }
    end

    assert_redirected_to polls_path
    assert_equal I18n.t('poll.error_csv_file_extension'), flash[:alert]
  end
end
