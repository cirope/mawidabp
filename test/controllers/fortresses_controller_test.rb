require 'test_helper'

class FortressesControllerTest < ActionController::TestCase
  fixtures :findings, :control_objective_items

  # Prueba que sin realizar autenticación esten accesibles las partes publicas
  # y no accesibles las privadas
  test 'public and private actions' do
    id_param = {:id => findings(:bcra_A4609_security_management_responsible_dependency_fortress).to_param}
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
      assert_equal I18n.t('message.must_be_authenticated'), flash.alert
    end

    public_actions.each do |action|
      send *action
      assert_response :success
    end
  end

  test 'list fortresses' do
    perform_auth
    get :index
    assert_response :success
    assert_not_nil assigns(:fortresses)
    assert_select '#error_body', false
    assert_template 'fortresses/index'
  end

  test 'list fortresses with search and sort' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4',
      :columns => ['description', 'review'],
      :order => 'review'
    }

    assert_response :success
    assert_not_nil assigns(:fortresses)
    assert_equal 2, assigns(:fortresses).size
    assert(assigns(:fortresses).all? do |o|
      o.review.identification.match(/1 2 4/i)
    end)
    assert_equal assigns(:fortresses).map {|o| o.review.identification}.sort,
      assigns(:fortresses).map {|o| o.review.identification}
    assert_select '#error_body', false
    assert_template 'fortresses/index'
  end

  test 'edit fortress when search match only one result' do
    perform_auth
    get :index, :search => {
      :query => '1 2 4 y 1f',
      :columns => ['description', 'review']
    }

    assert_redirected_to fortress_url(
      findings(:bcra_A4609_security_management_responsible_dependency_fortress))
    assert_not_nil assigns(:fortresses)
    assert_equal 1, assigns(:fortresses).size
  end

  test 'show fortress' do
    perform_auth
    get :show, :id => findings(:bcra_A4609_security_management_responsible_dependency_fortress).id
    assert_response :success
    assert_not_nil assigns(:fortress)
    assert_select '#error_body', false
    assert_template 'fortresses/show'
  end

  test 'new fortress' do
    perform_auth
    get :new, :control_objective_item => control_objective_items(
      :bcra_A4609_security_management_responsible_dependency_item_editable).id
    assert_response :success
    assert_not_nil assigns(:fortress)
    assert_select '#error_body', false
    assert_template 'fortresses/new'
  end

  test 'create fortress' do
    counts_array = ['Fortress.count', 'WorkPaper.count',
      'FindingRelation.count']

    perform_auth
    assert_difference counts_array do
      post :create, {
        :fortress => {
          :control_objective_item_id => control_objective_items(
            :bcra_A4609_data_proccessing_impact_analisys_item_editable).id,
          :review_code => 'F020',
          :description => 'New description',
          :origination_date => 1.day.ago.to_date.to_s(:db),
          :finding_user_assignments_attributes => {
            :new_1 => {
              :user_id => users(:audited_user).id, :process_owner => '1'
            },
            :new_2 => {
              :user_id => users(:auditor_user).id, :process_owner => '0'
            },
            :new_3 => {
              :user_id => users(:supervisor_user).id, :process_owner => '0'
            },
          },
          :work_papers_attributes => {
            :new_1 => {
              :name => 'New workpaper name',
              :code => 'PTF 20',
              :number_of_pages => '10',
              :description => 'New workpaper description',
              :organization_id => organizations(:default_organization).id,
              :file_model_attributes => {:file => Rack::Test::UploadedFile.new(
                  TEST_FILE_FULL_PATH, 'text/plain')
              }
            }
          },
          :finding_relations_attributes => {
            :new_1 => {
              :description => 'Duplicated',
              :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
            }
          }
        }
      }
    end
  end

  test 'edit fortress' do
    perform_auth
    get :edit, :id => findings(
      :bcra_A4609_security_management_responsible_dependency_fortress).id
    assert_response :success
    assert_not_nil assigns(:fortress)
    assert_select '#error_body', false
    assert_template 'fortresses/edit'
  end

  test 'update fortress' do
    perform_auth
    assert_no_difference 'Fortress.count' do
      assert_difference ['WorkPaper.count', 'FindingRelation.count'] do
        put :update, {
          :id => findings(
            :bcra_A4609_security_management_responsible_dependency_fortress).id,
          :fortress => {
            :control_objective_item_id => control_objective_items(
              :bcra_A4609_security_management_responsible_dependency_item_editable).id,
            :review_code => 'F005',
            :description => 'Updated description',
            :origination_date => 1.day.ago.to_date.to_s(:db),
            :finding_user_assignments_attributes => {
              finding_user_assignments(:bcra_A4609_security_management_responsible_dependency_fortress_audited_user).id => {
                :id => finding_user_assignments(:bcra_A4609_security_management_responsible_dependency_fortress_audited_user).id,
                :user_id => users(:audited_user).id,
                :process_owner => '1'
              },
              finding_user_assignments(:bcra_A4609_security_management_responsible_dependency_fortress_auditor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_security_management_responsible_dependency_fortress_auditor_user).id,
                :user_id => users(:auditor_user).id,
                :process_owner => '0'
              },
              finding_user_assignments(:bcra_A4609_security_management_responsible_dependency_fortress_supervisor_user).id => {
                :id => finding_user_assignments(:bcra_A4609_security_management_responsible_dependency_fortress_supervisor_user).id,
                :user_id => users(:supervisor_user).id,
                :process_owner => '0'
              }
            },
            :work_papers_attributes => {
              :new_1 => {
                :name => 'New workpaper name',
                :code => 'PTF 20',
                :number_of_pages => '10',
                :description => 'New workpaper description',
                :organization_id => organizations(:default_organization).id,
                :file_model_attributes => {
                  :file => Rack::Test::UploadedFile.new(
                    TEST_FILE_FULL_PATH, 'text/plain')
                }
              }
            },
            :finding_relations_attributes => {
              :new_1 => {
                :description => 'Duplicated',
                :related_finding_id => findings(:bcra_A4609_data_proccessing_impact_analisys_weakness).id
              }
            }
          }
        }
      end
    end

    assert_not_nil assigns(:fortress)
    assert_redirected_to edit_fortress_url(assigns(:fortress))
    assert_equal 'F005', assigns(:fortress).review_code
  end

  test 'auto complete for user' do
    perform_auth
    get :auto_complete_for_user, { :q => 'adm', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /adm/i }

    get :auto_complete_for_user, { :q => 'bar', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, users.size
    assert users.all? { |u| (u['label'] + u['informal']).match /bar/i }

    get :auto_complete_for_user, { :q => 'x_nobody', :format => :json }
    assert_response :success

    users = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, users.size # Sin resultados
  end

  test 'auto complete for control objective item' do
    perform_auth
    get :auto_complete_for_control_objective_item, {
      :q => 'dependencia',
      :review_id => reviews(:review_with_conclusion).id,
      :format => :json
    }
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 1, cois.size # bcra_A4609_security_management_responsible_dependency_item_editable
    assert cois.all? { |f| (f['label'] + f['informal']).match /dependencia/i }
    assert_equal(
      control_objective_items(:bcra_A4609_security_management_responsible_dependency_item_editable).id,
      cois.first['id']
    )

    get :auto_complete_for_control_objective_item, {
      :q => 'x_none',
      :review_id => reviews(:review_with_conclusion).id,
      :format => :json
    }
    assert_response :success

    cois = ActiveSupport::JSON.decode(@response.body)

    assert_equal 0, cois.size # Sin resultados
  end
end
