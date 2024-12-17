require 'test_helper'

class Findings::WorkPapersControllerTest < ActionController::TestCase
  setup do
    @finding = findings :unconfirmed_weakness

    login
    set_organization
  end

  test 'create finding work paper from finding answer' do
    last_work_paper_code =
      @controller.view_context.next_oportunity_work_paper_code @finding

    finding_answer = @finding.finding_answers.create!(
      answer: 'New answer',
      user_id: users(:supervisor).id,
      notify_users: false,
      file_model_attributes: {
        file: File.open(TEST_FILE_FULL_PATH)
      }
    )

    assert_difference '@finding.work_papers.count' do
      post :create, params: {
        finding_id:           @finding.id,
        completion_state:     'incomplete',
        finding_answer_id:    finding_answer.id,
        last_work_paper_code: last_work_paper_code
      }, xhr: true, as: :js
    end

    assert_response :success
    assert_match Mime[:js].to_s, @response.content_type
    assert @finding.reload.work_papers.last.file_model
  end

  test 'should be can remove work paper' do
    work_paper = work_papers :image_work_paper
    work_paper.revised!

    assert !@controller.view_context.can_remove_work_paper?(false, work_paper)

    supervisor = work_paper.
      owner.
        review.
          review_user_assignments.find_by(assignment_type: ReviewUserAssignment::TYPES[:supervisor]).user

    Current.user = supervisor

    assert @controller.view_context.can_remove_work_paper? false, work_paper
  end
end
