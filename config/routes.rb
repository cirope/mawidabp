MawidaApp::Application.routes.draw do
  resources :business_unit_types

  resources :groups

  resources :detracts, :only => [:index, :show, :new, :create] do
    member do
      get :show_last_detracts
    end

    # Cuando un usuario no tiene ningún detractor no incluye el ID
    collection do
      get :show
    end
  end

  resources :inline_helps

  match 'welcome', :as => 'welcome', :to => 'welcome#index'
  
  match 'execution_reports', :as => 'execution_reports',
    :to => 'execution_reports#index'

  [
    'weaknesses_by_state',
    'create_weaknesses_by_state',
    'detailed_management_report',
    'create_detailed_management_report'
  ].each do |action|
    match "execution_reports/#{action}", :to => "execution_reports##{action}",
      :as => action
  end

  resources :versions, :only => [:show] do
    collection do
      get :security_changes_report
    end
  end

  resources :help_items

  resources :help_contents do
    member do
      get :show_content
    end
    
    collection do
      get :show_content
    end
  end

  resources :notifications, :only => [:index, :show, :edit, :update] do
    member do
      get :confirm
    end
  end

  match 'conclusion_audit_reports', :as => 'conclusion_audit_reports',
    :to => 'conclusion_audit_reports#index'
  match 'conclusion_committee_reports', :as => 'conclusion_committee_reports',
    :to => 'conclusion_committee_reports#index'
  match 'conclusion_management_reports', :as => 'conclusion_management_reports',
    :to => 'conclusion_management_reports#index'
  match 'follow_up_audit', :as => 'follow_up_audit',
    :to => 'follow_up_audit#index'
  match 'follow_up_committee', :as => 'follow_up_committee',
    :to => 'follow_up_committee#index'
  match 'follow_up_management', :as => 'follow_up_management',
    :to => 'follow_up_management#index'

  [
    'weaknesses_by_state', 'create_weaknesses_by_state',
    'weaknesses_by_risk', 'create_weaknesses_by_risk',
    'weaknesses_by_audit_type', 'create_weaknesses_by_audit_type'
  ].each do |action|
    match "conclusion_management_reports/#{action}",
      :as => "#{action}_conclusion_management_reports",
      :to => "conclusion_management_reports##{action}"
    match "conclusion_audit_reports/#{action}",
      :as => "#{action}_conclusion_audit_reports",
      :to => "conclusion_audit_reports##{action}"
    match "follow_up_management/#{action}",
      :as => "#{action}_follow_up_management",
      :to => "follow_up_management##{action}"
    match "follow_up_audit/#{action}", :as => "#{action}_follow_up_audit",
      :to => "follow_up_audit##{action}"
  end

  [
    'cost_analysis', 'create_cost_analysis',
    'synthesis_report', 'create_synthesis_report',
    'weaknesses_by_state', 'create_weaknesses_by_state',
    'weaknesses_by_risk', 'create_weaknesses_by_risk',
    'weaknesses_by_audit_type', 'create_weaknesses_by_audit_type'
  ].each do |action|
    match "conclusion_committee_reports/#{action}",
      :as => "#{action}_conclusion_committee_reports",
      :to => "conclusion_committee_reports##{action}"
    match "follow_up_committee/#{action}",
      :as => "#{action}_follow_up_committee",
      :to => "follow_up_committee##{action}"
  end

  match "conclusion_committee_reports/cost_analysis",
    :as => 'cost_analysis_conclusion_committee_reports',
    :to => "conclusion_committee_reports#cost_analysis"
  match 'conclusion_committee_reports/cost_analysis/detailed',
    :as => 'detailed_cost_analysis_conclusion_committee_reports',
    :to => 'conclusion_committee_reports#cost_analysis',
    :include_details => 1

  match 'follow_up_committee/cost_analysis',
    :as => 'cost_analysis_follow_up_committee',
    :to => 'follow_up_committee#cost_analysis'

  scope ':completed', :completed => /complete|incomplete/ do
    resources :findings, :except => [:destroy] do
      resources :costs

      member do
        get :follow_up_pdf
      end

      collection do
        get :export_to_pdf
        post :auto_complete_for_user
        post :auto_complete_for_finding_relation
      end
    end
  end

  resources :workflows do
    member do
      get :export_to_pdf
    end

    collection do
      get :resource_data
      get :estimated_amount
      get :reviews_for_period
      post :auto_complete_for_user
    end
  end

  resources :conclusion_draft_reviews, :except => [:destroy] do
    member do
      get :check_for_approval
      get :export_to_pdf
      get :compose_email
      put :send_by_email
      get :download_work_papers
      get :score_sheet
      get :bundle
      post :create_bundle
    end

    collection do
      post :auto_complete_for_user
    end
  end

  resources :conclusion_final_reviews, :except => [:destroy] do
    member do
      get :export_to_pdf
      get :compose_email
      put :send_by_email
      get :download_work_papers
      get :score_sheet
      get :bundle
      post :create_bundle
    end

    collection do
      post :auto_complete_for_user
      get :export_list_to_pdf
    end
  end

  resources :reviews do
    member do
      get :survey_pdf
      get :review_data
      get :weaknesses_and_oportunities
      get :download_work_papers
      get :estimated_amount
      get :procedure_control_data
    end
    
    collection do
      get :estimated_amount
      get :plan_item_data
      post :auto_complete_for_user
      post :auto_complete_for_procedure_control_subitem
    end
  end

  resources :weaknesses do
    resources :costs

    collection do
      post :auto_complete_for_user
      post :auto_complete_for_finding_relation
    end
    
    member do
      get :follow_up_pdf
    end
  end

  resources :control_objective_items do
    member do
      get :suggest_next_work_paper_code
    end
  end

  resources :plans do
    member do
      get :export_to_pdf
    end

    collection do
      get :resource_data
      post :auto_complete_for_business_unit_business_unit_id
      post :auto_complete_for_user
    end
  end

  resources :resource_classes

  resources :procedure_controls do
    member do
      get :export_to_pdf
    end

    collection do
      get :get_control_objective
      get :get_control_objectives
      get :get_process_controls
    end
  end

  resources :best_practices

  resources :periods

  resources :oportunities do
    resources :costs

    member do
      get :follow_up_pdf
    end

    collection do
      post :auto_complete_for_user
      post :auto_complete_for_finding_relation
    end
  end

  resources :organizations

  resources :roles

  scope ':type', :type => /admin|security/ do
    resources :parameters, :except => [:new, :create, :destroy]
  end

  resources :error_records do
    collection do
      get :export_to_pdf
    end
  end

  resources :login_records, :only => [:index, :show] do
    collection do
      get :choose
      get :export_to_pdf
    end
  end

  resources :users do 
    collection do
      get :login
      post :create_session
      get :new_initial
      post :create_initial
      get :export_to_pdf
      post :auto_complete_for_user
      get :roles
      get :initial_roles
    end

    member do
      get :logout
      get :edit_password
      put :update_password
      get :edit_personal_data
      put :update_personal_data
      put :blank_password
      get :reassignment_edit
      put :reassignment_update
      get :release_edit
      put :release_update
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => 'users#login'

  match 'private/:path', :to => 'file_models#download',
    :constraints => { :path => /.+/ }
  match ':controller(/:action)/page/:page', :constraints => { :page => /\d+/ }

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end