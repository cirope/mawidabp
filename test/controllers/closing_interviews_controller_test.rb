require 'test_helper'

class ClosingInterviewsControllerTest < ActionController::TestCase
  setup do
    @closing_interview = closing_interviews :current

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:closing_interviews)
  end

  test 'should get filtered index' do
    get :index, params: {
      search: {
        query: '1 2 3',
        columns: ['review']
      }
    }
    assert_response :success
    assert_not_nil assigns(:closing_interviews)
    assert_equal 1, assigns(:closing_interviews).count
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should get new as JS' do
    get :new, params: { review_id: @closing_interview.review_id }, xhr: true,
      as: :js
    assert_response :success
    assert_equal Mime[:js], @response.content_type

    get :new, params: { review_id: nil}, xhr: true, as: :js
    assert_response :success
    assert_equal Mime[:js], @response.content_type
  end

  test 'should create closing interview' do
    review = reviews :current_review
    ruas   = review.review_user_assignments
    counts = [
      'ClosingInterview.count',
      'ClosingInterviewUser.responsible.count',
      'ClosingInterviewUser.auditor.count',
      'ClosingInterviewUser.assistant.count'
    ]

    assert_difference counts do
      post :create, params: {
        closing_interview: {
          review_id:               review.id,
          interview_date:          I18n.l(Time.zone.today),
          findings_summary:        'Interview findings summary',
          recommendations_summary: 'Interview recommendations summary',
          suggestions:             'Interview suggestions',
          comments:                'Interview comments',
          audit_comments:          'Interview audit comments',
          responsible_comments:    'Interview responsible comments',
          responsibles_attributes: ruas.select(&:audited?).map do |rua|
            { user_id: rua.user_id }
          end,
          auditors_attributes: ruas.select(&:auditor?).map do |rua|
            { user_id: rua.user_id }
          end,
          assistants_attributes: [
            { user_id: users(:administrator).id }
          ]
        }
      }
    end

    assert_redirected_to closing_interview_url(assigns(:closing_interview))
  end

  test 'should show closing interview' do
    get :show, params: { id: @closing_interview }
    assert_response :success
  end

  test 'should show closing interview as PDF' do
    get :show, params: { id: @closing_interview }, as: :pdf
    assert_response :redirect
    assert_equal Mime[:pdf], @response.content_type
  end

  test 'should get edit' do
    get :edit, params: { id: @closing_interview }
    assert_response :success
  end

  test 'should update closing interview' do
    patch :update, params: {
      id: @closing_interview, closing_interview: { comments: 'New comments' }
    }

    assert_redirected_to closing_interview_url(assigns(:closing_interview))
    assert_equal 'New comments', @closing_interview.reload.comments
  end

  test 'should destroy closing interview' do
    assert_difference 'ClosingInterview.count', -1 do
      delete :destroy, params: { id: @closing_interview }
    end

    assert_redirected_to closing_interviews_url
  end
end
