require 'test_helper'

class OpeningInterviewsControllerTest < ActionController::TestCase
  setup do
    @opening_interview = opening_interviews :current

    login
  end

  test 'should get index' do
    get :index
    assert_response :success
    assert_not_nil assigns(:opening_interviews)
  end

  test 'should get filtered index' do
    get :index, params: {
      search: {
        query: '1 2 5',
        columns: ['review']
      }
    }
    assert_response :success
    assert_not_nil assigns(:opening_interviews)
    assert_equal 1, assigns(:opening_interviews).count
  end

  test 'should get new' do
    get :new
    assert_response :success
  end

  test 'should get new as JS' do
    get :new, params: { review_id: @opening_interview.review_id }, xhr: true,
      as: :js
    assert_response :success
    assert_equal Mime[:js], @response.content_type

    get :new, params: { review_id: nil}, xhr: true, as: :js
    assert_response :success
    assert_equal Mime[:js], @response.content_type
  end

  test 'should create opening interview' do
    review = reviews :review_with_conclusion
    ruas   = review.review_user_assignments
    counts = [
      'OpeningInterview.count',
      'OpeningInterviewUser.responsible.count',
      'OpeningInterviewUser.assistant.count'
    ]

    assert_difference counts do
      assert_difference 'OpeningInterviewUser.auditor.count', 3 do
        post :create, params: {
          opening_interview: {
            review_id:      review.id,
            interview_date: I18n.l(Time.zone.today),
            start_date:     I18n.l(2.days.ago.to_date),
            end_date:       I18n.l(2.days.from_now.to_date),
            objective:      'Interview objective',
            program:        'Interview program',
            scope:          'Interview scope',
            suggestions:    'Interview suggestions',
            comments:       'Interview comments',
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
    end

    assert_redirected_to opening_interview_url(assigns(:opening_interview))
  end

  test 'should show opening interview' do
    get :show, params: { id: @opening_interview }
    assert_response :success
  end

  test 'should show opening interview as PDF' do
    get :show, params: { id: @opening_interview }, as: :pdf
    assert_response :redirect
    assert_equal Mime[:pdf], @response.content_type
  end

  test 'should get edit' do
    get :edit, params: { id: @opening_interview }
    assert_response :success
  end

  test 'should update opening interview' do
    patch :update, params: {
      id: @opening_interview, opening_interview: { objective: 'New objective' }
    }

    assert_redirected_to opening_interview_url(assigns(:opening_interview))
    assert_equal 'New objective', @opening_interview.reload.objective
  end

  test 'should destroy opening interview' do
    @opening_interview.review.closing_interview.destroy!

    assert_difference 'OpeningInterview.count', -1 do
      delete :destroy, params: { id: @opening_interview }
    end

    assert_redirected_to opening_interviews_url
  end
end
