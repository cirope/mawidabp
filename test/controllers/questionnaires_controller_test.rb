require 'test_helper'

class QuestionnairesControllerTest < ActionController::TestCase

  test 'public and private actions' do
    id_param = {id: questionnaires(:questionnaire_one).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:delete, :destroy, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to controller: :users, action: :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list questionnaires' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:questionnaires)
    assert_select '#error_body', false
    assert_template 'questionnaires/index'
  end

  test 'show questionnaire' do
    perform_auth
    get :show, id: questionnaires(:questionnaire_one).id
    assert_response :success
    assert_not_nil assigns(:questionnaire)
    assert_select '#error_body', false
    assert_template 'questionnaires/show'
  end

  test 'new questionnaire' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:questionnaire)
    assert_select '#error_body', false
    assert_template 'questionnaires/new'
  end

  test 'create questionnaire' do
    perform_auth
    assert_difference 'Questionnaire.count' do
      assert_difference 'Question.count', 2 do
        assert_difference 'AnswerOption.count', 5 do
          post :create, {
            questionnaire: {
              name: "Nuevo cuestionario",
              email_text: "Email text",
              email_link: "Email link",
              email_subject: "Email subject",
              questions_attributes: [
                {
                  question: "Cuestion multi choice",
                  sort_order: 1,
                  answer_type: 1
                }, {
                  question: "Cuestion written",
                  sort_order: 2,
                  answer_type: 0
                }
              ]
            }
          }
  p @response.body
        end
      end
    end
    assert_redirected_to questionnaire_path(assigns(:questionnaire))
  end

  test 'edit questionnaire' do
    perform_auth
    get :edit, id: questionnaires(:questionnaire_one).id
    assert_response :success
    assert_not_nil assigns(:questionnaire)
    assert_select '#error_body', false
    assert_template 'questionnaires/edit'
  end

  test "update questionnaire" do
    perform_auth
    assert_no_difference ['Questionnaire.count', 'Question.count'] do
      patch :update, {
        id: questionnaires(:questionnaire_one).id,
        questionnaire: {
          name: 'Cuestionario actualizado',
          questions_attributes: [
            {
              id: questions(:question_multi_choice).id,
              question: 'Cuestion updated',
              sort_order: 1,
              answer_type: 1,
            }
          ]
        }
      }
    end

    assert_redirected_to questionnaires_url
    assert_not_nil assigns(:questionnaire)
    assert_equal 'Cuestionario actualizado', assigns(:questionnaire).name
    assert_equal 'Cuestion updated', Question.find(
      questions(:question_multi_choice).id).question
    end

  test 'destroy questionnaire' do
    perform_auth
    assert_difference ['Questionnaire.count'], -1 do
      assert_difference 'Question.count', -2 do
        assert_difference ['AnswerOption.count'], -5 do
          delete :destroy, id: questionnaires(:questionnaire_one).id
        end
      end
    end
    assert_redirected_to questionnaires_url
  end
end
