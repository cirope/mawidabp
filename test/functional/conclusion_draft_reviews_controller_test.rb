require 'test_helper'

# Pruebas para el controlador de informes borradores
class ConclusionDraftReviewsControllerTest < ActionController::TestCase
  fixtures :conclusion_reviews

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @request.host = "#{organizations(:default_organization).prefix}.localhost.i"
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => conclusion_reviews(:conclusion_with_conclusion_draft_review).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:put, :update, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t(:'message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list conclusion_draft_reviews' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'list conclusion_draft_reviews with search' do
    perform_auth
    get :index, :search => {
      :query => '1 2',
      :columns => ['identification', 'project']
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 2, assigns(:conclusion_draft_reviews).size
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'list conclusion_draft_reviews with search by date and sort' do
    perform_auth
    get :index, :search => {
      :query => "> #{I18n.l(3.months.ago.to_date, :format => :minimal)}",
      :columns => ['issue_date']
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 2, assigns(:conclusion_draft_reviews).size
    assert assigns(:conclusion_draft_reviews).all? {|cdr| cdr.issue_date > 3.months.ago.to_date}
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'edit conclusion_draft_reviews when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['identification', 'project']
    }
    assert_redirected_to edit_conclusion_draft_review_path(conclusion_reviews(:conclusion_with_conclusion_draft_review))
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 1, assigns(:conclusion_draft_reviews).size
  end

  test 'edit conclusion_draft_reviews when search by date match only one result' do
    perform_auth
    get :index, :search => {
      :query => "< #{I18n.l(3.months.ago.to_date, :format => :minimal)}",
      :columns => ['issue_date']
    }

    assert_redirected_to edit_conclusion_draft_review_path(conclusion_reviews(
        :conclusion_with_conclusion_draft_review))
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 1, assigns(:conclusion_draft_reviews).size
  end

  test 'list only one conclusion_draft_reviews with search on one with final' do
    perform_auth
    get :index, :search => {
      :query => '1 1',
      :columns => ['identification', 'project']
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 1, assigns(:conclusion_draft_reviews).size
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'show conclusion_draft_review' do
    perform_auth
    get :show, :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/show'
  end

  test 'new conclusion_draft_review' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/new'
  end

  test 'create conclusion_draft_review' do
    perform_auth
    assert_difference 'ConclusionDraftReview.count' do
      post :create, {
        :conclusion_draft_review => {
          :review_id => reviews(:review_without_conclusion).id,
          :issue_date => Time.now.to_date,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => 'New conclusion'
        }
      }
    end
  end

  test 'edit conclusion_draft_review' do
    perform_auth
    get :edit, :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/edit'
  end

  test 'update conclusion_draft_review' do
    assert_no_difference 'ConclusionDraftReview.count' do
      perform_auth
      put :update, {
        :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id,
        :conclusion_draft_review => {
          :review_id => reviews(:review_with_conclusion).id,
          :issue_date => Time.now.to_date,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'Updated applied procedures',
          :conclusion => 'Updated conclusion'
        }
      }
    end

    assert_redirected_to conclusion_draft_reviews_path
    assert_not_nil assigns(:conclusion_draft_review)
    assert_equal 'Updated conclusion',
      assigns(:conclusion_draft_review).conclusion
  end

  test 'export conclusion draft review' do
    perform_auth

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :id => conclusion_review.id
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'score sheet of final review' do
    perform_auth

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised(Exception) do
      get :score_sheet, :id => conclusion_review.id
    end

    assert_redirected_to conclusion_review.review.relative_score_sheet_path

    assert_nothing_raised(Exception) do
      get :score_sheet, :id => conclusion_review.id, :global => 1
    end

    assert_redirected_to(
      conclusion_review.review.relative_global_score_sheet_path)
  end

  test 'download work papers' do
    perform_auth

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised(Exception) do
      get :download_work_papers, :id => conclusion_review.id
    end

    assert_redirected_to conclusion_review.review.relative_work_papers_zip_path
  end

  test 'bundle' do
    perform_auth
    get :bundle, :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/bundle'
  end

  test 'download bundle' do
    perform_auth

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised(Exception) do
      post :create_bundle, :id => conclusion_review.id,
        :index_items => "one\ntwo"
    end

    assert_redirected_to conclusion_review.relative_bundle_zip_path
    FileUtils.rm conclusion_review.absolute_bundle_zip_path
  end

  test 'check for approval' do
    perform_auth
    get :check_for_approval, :id => reviews(:current_review).id,
      :format => :json
    assert_response :success

    approval_hash = nil

    assert_nothing_raised(Exception) do
      approval_hash = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil approval_hash
    assert approval_hash.has_key?('approved')
    assert approval_hash.has_key?('errors')
    assert_kind_of Array, approval_hash['errors']
  end

  test 'compose email' do
    perform_auth
    get :compose_email,
      :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/compose_email'
  end

  test 'send by email' do
    perform_auth
    conclusion_review = ConclusionDraftReview.find(conclusion_reviews(
        :conclusion_with_conclusion_draft_review).id)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      put :send_by_email, {
        :id => conclusion_review.id,
        :user => {
          users(:administrator_user).id => {
            :id => users(:administrator_user).id,
            :data => users(:administrator_user).name
          },
          # Con duplicados igual envía solo un correo
          users(:administrator_user).id + 1 => {
            :id => users(:administrator_user).id,
            :data => users(:administrator_user).name
          }
        }
      }
    end

    assert_redirected_to :action => :edit, :id => conclusion_review.id
    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      put :send_by_email, {
        :id => conclusion_review.id,
        :user => {
          users(:administrator_user).id => {
            :id => users(:administrator_user).id,
            :data => users(:administrator_user).name
          },
          # Sin confirmación
          users(:audited_user).id => {
            :id => users(:audited_user).id,
            :data => users(:audited_user).name
          }
        }
      }
    end

    assert_redirected_to :action => :edit, :id => conclusion_review.id
    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
  end

  test 'send by email with multiple attachments' do
    perform_auth
    conclusion_review = ConclusionDraftReview.find(conclusion_reviews(
        :conclusion_with_conclusion_draft_review).id)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      put :send_by_email, {
        :id => conclusion_review.id,
        :conclusion_review => {
          :include_score_sheet => '1',
          :email_note => 'note in *textile* _format_'
        },
        :user => {
          users(:administrator_user).id => {
            :id => users(:administrator_user).id,
            :data => users(:administrator_user).name
          }
        }
      }
    end

    assert_equal 2, ActionMailer::Base.deliveries.last.attachments.size

    text_part = ActionMailer::Base.deliveries.last.parts.detect {
      |p| p.content_type.match(/text/)
    }.body.decoded

    assert_match /textile/, text_part

    assert_difference 'ActionMailer::Base.deliveries.size' do
      put :send_by_email, {
        :id => conclusion_review.id,
        :conclusion_review => {
          :include_score_sheet => '1',
          :include_global_score_sheet => '1',
          :email_note => 'note in *textile* _format_'
        },
        :user => {
          users(:administrator_user).id => {
            :id => users(:administrator_user).id,
            :data => users(:administrator_user).name
          }
        }
      }
    end

    assert_equal 3, ActionMailer::Base.deliveries.last.attachments.size

    text_part = ActionMailer::Base.deliveries.last.parts.detect {
      |p| p.content_type.match(/text/)
    }.body.decoded

    assert_match /textile/, text_part
  end

  test 'can not send by email with final review' do
    perform_auth
    conclusion_review = ConclusionDraftReview.find(conclusion_reviews(
        :conclusion_current_draft_review).id)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      put :send_by_email, {
        :id => conclusion_review.id,
        :user => {
          users(:administrator_user).id => {
            :id => users(:administrator_user).id,
            :data => users(:administrator_user).name
          }
        }
      }
    end

    # Produce un error cuando se trata de buscar un informe borrador que ya
    # tiene definitivo
    assert_redirected_to :action => :index
  end

  test 'auto complete for user' do
    perform_auth
    post :auto_complete_for_user, { :user_data => 'admin' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 1, assigns(:users).size # Administrator
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'blank' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 2, assigns(:users).size # Blank and Expired blank
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/auto_complete_for_user'

    post :auto_complete_for_user, { :user_data => 'xyz' }
    assert_response :success
    assert_not_nil assigns(:users)
    assert_equal 0, assigns(:users).size # None
    assert_select '#error_body', false
    assert_template 'conclusion_draft_reviews/auto_complete_for_user'
  end
end