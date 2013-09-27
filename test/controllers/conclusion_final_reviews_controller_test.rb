require 'test_helper'

# Pruebas para el controlador de informes finales
class ConclusionFinalReviewsControllerTest < ActionController::TestCase
  fixtures :conclusion_reviews

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  def setup
    @request.host = "#{organizations(:default_organization).prefix}.localhost.i"
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => conclusion_reviews(:conclusion_past_final_review).to_param}
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param],
      [:get, :export_to_pdf, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to :controller => :users, :action => :login
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list conclusion_final_reviews' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/index'
  end

  test 'list conclusion_final_reviews with search' do
    perform_auth
    get :index, :search => {
      :query => '1',
      :columns => ['identification', 'project']
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_equal 2, assigns(:conclusion_final_reviews).size
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/index'
  end

  test 'list conclusion_final_reviews with search by date and sort' do
    perform_auth
    get :index, :search => {
      :query => "> #{I18n.l(3.months.ago.to_date, :format => :minimal)}",
      :columns => ['issue_date']
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_equal 2, assigns(:conclusion_final_reviews).size
    assert assigns(:conclusion_final_reviews).all? {|cfr| cfr.issue_date > 3.months.ago.to_date}
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/index'
  end

  test 'edit conclusion_final_reviews when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 3',
      :columns => ['identification', 'project']
    }
    assert_redirected_to conclusion_final_review_url(conclusion_reviews(:conclusion_current_final_review))
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_equal 1, assigns(:conclusion_final_reviews).size
  end

  test 'edit conclusion_final_reviews when search by date match only one result' do
    perform_auth
    get :index, :search => {
      :query => "> #{I18n.l(5.days.ago.to_date, :format => :minimal)}",
      :columns => ['issue_date']
    }

    assert_redirected_to conclusion_final_review_url(conclusion_reviews(:conclusion_current_final_review))
    assert_not_nil assigns(:conclusion_final_reviews)
    assert_equal 1, assigns(:conclusion_final_reviews).size
  end

  test 'show conclusion_final_review' do
    perform_auth
    get :show, :id => conclusion_reviews(:conclusion_past_final_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/show'
  end

  test 'new conclusion final review' do
    perform_auth
    get :new
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/new'
  end

  test 'new json conclusion final review' do
    perform_auth
    xhr :get, :new, :format => 'json'
    assert_response :success
    assert_nothing_raised(Exception) do
      ActiveSupport::JSON.decode(@response.body)
    end
  end

  test 'new for existent conclusion final review' do
    perform_auth
    get :new, :review =>
      conclusion_reviews(:conclusion_past_final_review).review_id
    assert_redirected_to edit_conclusion_final_review_url(
      conclusion_reviews(:conclusion_past_final_review))
  end

  test 'create conclusion final review' do
    perform_auth
    assert_difference 'ConclusionFinalReview.count' do
      post :create, {
        :conclusion_final_review => {
          :review_id => reviews(:review_approved_with_conclusion).id,
          :issue_date => Date.today,
          :close_date => Date.tomorrow,
          :applied_procedures => 'New applied procedures',
          :conclusion => 'New conclusion'
        }
      }
    end
  end

  test 'edit conclusion final review' do
    perform_auth
    get :edit, :id => conclusion_reviews(:conclusion_past_final_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/edit'
  end

  test 'update conclusion final review' do
    assert_no_difference 'ConclusionFinalReview.count' do
      perform_auth
      patch :update, {
        :id => conclusion_reviews(:conclusion_past_final_review).id,
        :conclusion_final_review => {
          :review_id => reviews(:review_with_conclusion).id,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'Updated applied procedures',
          :conclusion => 'Updated conclusion'
        }
      }
    end
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_equal 'Updated conclusion',
      assigns(:conclusion_final_review).conclusion
  end

  test 'export conclusion final review' do
    perform_auth

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :id => conclusion_review.id
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'export conclusion draft review without control objectives excluded from score' do
    perform_auth

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised(Exception) do
      get :export_to_pdf, :id => conclusion_review.id,
        :export_options => {:hide_control_objectives_excluded_from_score => '1'}
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'score sheet of final review' do
    perform_auth

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

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

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised(Exception) do
      get :download_work_papers, :id => conclusion_review.id
    end

    assert_redirected_to conclusion_review.review.relative_work_papers_zip_path
  end

  test 'bundle' do
    perform_auth
    get :bundle, :id => conclusion_reviews(:conclusion_past_final_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/bundle'
  end

  test 'download bundle' do
    perform_auth

    conclusion_review = ConclusionFinalReview.find(
      conclusion_reviews(:conclusion_past_final_review).id)

    assert_nothing_raised(Exception) do
      post :create_bundle, :id => conclusion_review.id,
        :index_items => "one\ntwo"
    end

    assert_redirected_to conclusion_review.relative_bundle_zip_path
    FileUtils.rm conclusion_review.absolute_bundle_zip_path
  end

  test 'compose email' do
    perform_auth
    get :compose_email,
      :id => conclusion_reviews(:conclusion_past_final_review).id
    assert_response :success
    assert_not_nil assigns(:conclusion_final_review)
    assert_select '#error_body', false
    assert_template 'conclusion_final_reviews/compose_email'
  end

  test 'send by email' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :send_by_email, {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
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

    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
    assert_redirected_to :action => :edit, :id => conclusion_reviews(
      :conclusion_current_final_review).id

    assert_difference 'ActionMailer::Base.deliveries.size', 2 do
      patch :send_by_email, {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
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

    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
    assert_redirected_to :action => :edit, :id => conclusion_reviews(
      :conclusion_current_final_review).id
  end

  test 'send by email with multiple attachments' do
    perform_auth

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_difference 'ActionMailer::Base.deliveries.size' do
      patch :send_by_email, {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
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
      patch :send_by_email, {
        :id => conclusion_reviews(:conclusion_current_final_review).id,
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

  test 'export list to pdf' do
    perform_auth

    assert_nothing_raised(Exception) { get :export_list_to_pdf }

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_final_review.pdf.pdf_name'),
      ConclusionFinalReview.table_name)
  end

  test 'export list with search' do
    perform_auth

    assert_nothing_raised(Exception) do
      get :export_list_to_pdf, :search => {
        :query => '1',
        :columns => ['period', 'identification']
      }
    end

    assert_redirected_to Prawn::Document.relative_path(
      I18n.t('conclusion_final_review.pdf.pdf_name'),
      ConclusionFinalReview.table_name)
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { :q => 'admin', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size # Administrator
    assert users.all? { |u| (u['label'] + u['informal']).match /admin/i }

    get :auto_complete_for_user, { :q => 'blank', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 2, users.size # Blank and Expired blank
    assert users.all? { |u| (u['label'] + u['informal']).match /blank/i }

    get :auto_complete_for_user, { :q => 'xyz', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size # None
  end
end
