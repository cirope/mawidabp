require 'test_helper'

# Pruebas para el controlador de informes borradores
class ConclusionDraftReviewsControllerTest < ActionController::TestCase
  include ActiveJob::TestHelper

  fixtures :conclusion_reviews

  # Inicializa de forma correcta todas las variables que se utilizan en las
  # pruebas
  setup do
    set_host_for_organization(organizations(:cirope).prefix)
    set_organization organizations(:cirope)
  end

  teardown do
    Current.organization = nil

    clear_enqueued_jobs
    clear_performed_jobs
  end

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {
      params: {
        :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).to_param
      }
    }
    public_actions = []
    private_actions = [
      [:get, :index],
      [:get, :show, id_param],
      [:get, :new],
      [:get, :edit, id_param],
      [:post, :create],
      [:patch, :update, id_param]
    ]

    private_actions.each do |action|
      send *action
      assert_redirected_to login_url
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list conclusion_draft_reviews' do
    login
    get :index
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'list conclusion_draft_reviews with search' do
    login
    get :index, :params => {
      :search => {
        :query => '1 2',
        :columns => ['identification', 'project']
      }
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 3, assigns(:conclusion_draft_reviews).count
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'list conclusion_draft_reviews with search by date and sort' do
    login
    get :index, :params => {
      :search => {
        :query => "> #{I18n.l(1.month.ago.to_date, :format => :minimal)}",
        :columns => ['issue_date']
      }
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 3, assigns(:conclusion_draft_reviews).count
    assert assigns(:conclusion_draft_reviews).all? {|cdr| cdr.issue_date > 3.months.ago.to_date}
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'list only one conclusion_draft_reviews with search on one with final' do
    login
    get :index, :params => {
      :search => {
        :query => '1 1',
        :columns => ['identification', 'project']
      }
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_reviews)
    assert_equal 1, assigns(:conclusion_draft_reviews).count
    assert_template 'conclusion_draft_reviews/index'
  end

  test 'show conclusion draft review' do
    login
    get :show, :params => {
      :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_template 'conclusion_draft_reviews/show'
  end

  test 'new conclusion draft review' do
    login
    get :new
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_template 'conclusion_draft_reviews/new'
  end

  test 'new js conclusion draft review' do
    login
    get :new, xhr: true, as: :js
    assert_response :success
    assert_equal Mime[:js], @response.content_type
  end

  test 'create conclusion draft review' do
    login
    assert_difference 'ConclusionDraftReview.count' do
      post :create, :params => {
        :conclusion_draft_review => {
          :review_id => reviews(:review_without_conclusion).id,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'New applied procedures',
          :conclusion => CONCLUSION_OPTIONS.first,
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => EVOLUTION_OPTIONS.second,
          :evolution_justification => 'Ok',
          :observations => nil,
          :main_weaknesses_text => 'Some main weakness X',
          :corrective_actions => 'You should do it this way',
          :affects_compliance => '0'
        }
      }
    end

    assert_redirected_to edit_conclusion_draft_review_url(assigns(:conclusion_draft_review))
  end

  test 'edit conclusion draft review' do
    login
    get :edit, :params => {
      :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    }
    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_template 'conclusion_draft_reviews/edit'
  end

  test 'update conclusion draft review' do
    assert_no_difference 'ConclusionDraftReview.count' do
      login
      patch :update, :params => {
        :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id,
        :conclusion_draft_review => {
          :review_id => reviews(:review_with_conclusion).id,
          :issue_date => Date.today,
          :close_date => 2.days.from_now.to_date,
          :applied_procedures => 'Updated applied procedures',
          :conclusion => CONCLUSION_OPTIONS.first,
          :recipients => 'John Doe',
          :sectors => 'Area 51',
          :evolution => EVOLUTION_OPTIONS.second,
          :evolution_justification => 'Ok',
          :main_weaknesses_text => 'Some main weakness X',
          :corrective_actions => 'You should do it this way',
          :affects_compliance => '0',
          :observations => nil
        }
      }
    end

    assert_redirected_to edit_conclusion_draft_review_url(assigns(:conclusion_draft_review))
    assert_not_nil assigns(:conclusion_draft_review)
    assert_equal 'Updated applied procedures',
      assigns(:conclusion_draft_review).applied_procedures
  end

  test 'export conclusion draft review' do
    login

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => { :id => conclusion_review.id }
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'export conclusion draft review without score' do
    login

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => {
        :id => conclusion_review.id,
        :export_options => { :hide_score => '1' }
      }
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'export conclusion draft review brief' do
    login

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised do
      get :export_to_pdf, :params => {
        :id => conclusion_review.id,
        :export_options => { :brief => '1' }
      }
    end

    assert_redirected_to conclusion_review.relative_pdf_path
  end

  test 'score sheet of draft review' do
    login

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised do
      get :score_sheet, :params => { :id => conclusion_review.id }
    end

    assert_redirected_to conclusion_review.review.relative_score_sheet_path

    assert_nothing_raised do
      get :score_sheet, :params => { :id => conclusion_review.id, :global => 1 }
    end

    assert_redirected_to(
      conclusion_review.review.relative_global_score_sheet_path)
  end

  test 'download work papers' do
    login

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised do
      get :download_work_papers, :params => { :id => conclusion_review.id }
    end

    assert_redirected_to conclusion_review.review.relative_work_papers_zip_path
  end

  test 'download bundle' do
    login

    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_with_conclusion_draft_review).id)

    assert_nothing_raised do
      post :create_bundle, :params => {
        :id => conclusion_review.id,
        :index_items => "one\ntwo"
      }
    end

    assert_redirected_to conclusion_review.relative_bundle_zip_path
    FileUtils.rm conclusion_review.absolute_bundle_zip_path
  end

  test 'check for approval' do
    login
    get :check_for_approval, :params => {
      :id => reviews(:current_review).id
    }, :as => :json

    assert_response :success

    approval_hash = nil

    assert_nothing_raised do
      approval_hash = ActiveSupport::JSON.decode(@response.body)
    end

    assert_not_nil approval_hash
    assert approval_hash.has_key?('approved')
    assert approval_hash.has_key?('errors')
    assert_kind_of Array, approval_hash['errors']
  end

  test 'compose email' do
    login
    get :compose_email, :params => {
      :id => conclusion_reviews(:conclusion_with_conclusion_draft_review).id
    }

    assert_response :success
    assert_not_nil assigns(:conclusion_draft_review)
    assert_template 'conclusion_draft_reviews/compose_email'
  end

  test 'send by email' do
    login
    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_approved_with_conclusion_draft_review).id
    )

    ActionMailer::Base.deliveries = []

    assert_enqueued_jobs 1 do
      patch :send_by_email, :params => {
        :id => conclusion_review.id,
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          },
          # Con duplicados igual envía solo un correo
          users(:administrator).id + 1 => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    perform_job_with_current_attributes(enqueued_jobs.first)

    assert_redirected_to :action => :edit, :id => conclusion_review.id
    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size

    clear_enqueued_jobs
    clear_performed_jobs

    assert_enqueued_jobs 2 do
      patch :send_by_email, :params => {
        :id => conclusion_review.id,
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          },
          # Sin confirmación
          users(:audited).id => {
            :id => users(:audited).id,
            :data => users(:audited).name
          }
        }
      }
    end

    enqueued_jobs.each do |job|
      perform_job_with_current_attributes(job)
    end

    assert_redirected_to :action => :edit, :id => conclusion_review.id
    assert_equal 1, ActionMailer::Base.deliveries.last.attachments.size
  end

  test 'send by email with multiple attachments' do
    login
    conclusion_review = ConclusionDraftReview.find(
      conclusion_reviews(:conclusion_approved_with_conclusion_draft_review).id
    )

    ActionMailer::Base.deliveries = []

    assert_enqueued_jobs 1 do
      patch :send_by_email, :params => {
        :id => conclusion_review.id,
        :conclusion_review => {
          :include_score_sheet => '1',
          :email_note => 'note in **markdown** _format_'
        },
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    perform_job_with_current_attributes(enqueued_jobs.first)

    assert_equal 2, ActionMailer::Base.deliveries.last.attachments.size

    text_part = ActionMailer::Base.deliveries.last.parts.detect {
      |p| p.content_type.match(/text/)
    }.body.decoded

    assert_match /markdown/, text_part

    clear_enqueued_jobs
    clear_performed_jobs

    assert_enqueued_jobs 1 do
      patch :send_by_email, :params => {
        :id => conclusion_review.id,
        :conclusion_review => {
          :include_score_sheet => '1',
          :include_global_score_sheet => '1',
          :email_note => 'note in **markdown** _format_'
        },
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    perform_job_with_current_attributes(enqueued_jobs.first)

    assert_equal 3, ActionMailer::Base.deliveries.last.attachments.size

    text_part = ActionMailer::Base.deliveries.last.parts.detect {
      |p| p.content_type.match(/text/)
    }.body.decoded

    assert_match /markdown/, text_part
  end

  test 'can not send by email with final review' do
    login
    conclusion_review = ConclusionDraftReview.find(conclusion_reviews(
        :conclusion_current_draft_review).id)

    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    assert_no_difference 'ActionMailer::Base.deliveries.size' do
      patch :send_by_email, :params => {
        :id => conclusion_review.id,
        :user => {
          users(:administrator).id => {
            :id => users(:administrator).id,
            :data => users(:administrator).name
          }
        }
      }
    end

    # Produce un error cuando se trata de buscar un informe borrador que ya
    # tiene definitivo
    assert_redirected_to :action => :index
  end

  test 'corrective actions update' do
    login
    get :corrective_actions_update, xhr: true, as: :js
    assert_response :success
    assert_equal @response.content_type, Mime[:js]
  end
end
