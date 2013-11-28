MawidaBP::Application.routes.draw do
  resources :settings, only: [:index, :show, :edit, :update]

  resources :questionnaires

  resources :polls do
    collection do
      get :auto_complete_for_user
      get :import_csv_customers
      post :send_csv_polls
      get :reports
      get :summary_by_questionnaire
      get :summary_by_answers
      get :summary_by_business_unit
      post :create_summary_by_questionnaire
      post :create_summary_by_answers
      post :create_summary_by_business_unit
    end
  end

  resources :e_mails, :only => [:index, :show]

  resources :business_unit_types

  resources :fortresses do
    resources :costs

    collection do
      get :auto_complete_for_user
      get :auto_complete_for_control_objective_item
    end
  end

  resources :groups

  resources :inline_helps

  get 'welcome', as: 'welcome', to: 'welcome#index'
  get 'execution_reports', as: 'execution_reports', to: 'execution_reports#index'

  [
    'weaknesses_by_state_execution',
    'detailed_management_report'
  ].each do |action|
    get "execution_reports/#{action}", to: "execution_reports##{action}", as: action
  end

  [
    'create_weaknesses_by_state_execution',
    'create_detailed_management_report'
  ].each do |action|
    post "execution_reports/#{action}", to: "execution_reports##{action}", as: action
  end

  resources :versions, only: [:show] do
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

  resources :notifications, only: [:index, :show, :edit, :update] do
    member do
      get :confirm
    end
  end

  get 'conclusion_audit_reports', as: 'conclusion_audit_reports',
    to: 'conclusion_audit_reports#index'
  get 'conclusion_committee_reports', as: 'conclusion_committee_reports',
    to: 'conclusion_committee_reports#index'
  get 'conclusion_management_reports', as: 'conclusion_management_reports',
    to: 'conclusion_management_reports#index'
  get 'follow_up_audit', as: 'follow_up_audit', to: 'follow_up_audit#index'
  get 'follow_up_committee', as: 'follow_up_committee', to: 'follow_up_committee#index'
  get 'follow_up_management', as: 'follow_up_management', to: 'follow_up_management#index'

  [
    'weaknesses_by_state',
    'weaknesses_by_risk',
    'weaknesses_by_audit_type',
    'control_objective_stats',
    'process_control_stats'
  ].each do |action|
    get "conclusion_management_reports/#{action}",
      as: "#{action}_conclusion_management_reports",
      to: "conclusion_management_reports##{action}"
    get "conclusion_audit_reports/#{action}",
      as: "#{action}_conclusion_audit_reports",
      to: "conclusion_audit_reports##{action}"
    get "follow_up_management/#{action}",
      as: "#{action}_follow_up_management",
      to: "follow_up_management##{action}"
    get "follow_up_audit/#{action}", as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
  end

  [
    'create_weaknesses_by_state',
    'create_weaknesses_by_risk',
    'create_weaknesses_by_audit_type',
    'create_control_objective_stats',
    'create_process_control_stats'
  ].each do |action|
    post "conclusion_management_reports/#{action}",
      :as => "#{action}_conclusion_management_reports",
      :to => "conclusion_management_reports##{action}"
    post "conclusion_audit_reports/#{action}",
      :as => "#{action}_conclusion_audit_reports",
      :to => "conclusion_audit_reports##{action}"
    post "follow_up_management/#{action}",
      :as => "#{action}_follow_up_management",
      :to => "follow_up_management##{action}"
    post "follow_up_audit/#{action}", :as => "#{action}_follow_up_audit",
      :to => "follow_up_audit##{action}"
  end

  [
    'qa_indicators',
    'synthesis_report',
    'control_objective_stats',
    'process_control_stats',
    'rescheduled_being_implemented_weaknesses_report'
  ].each do |action|
    get "conclusion_committee_reports/#{action}",
      :as => "#{action}_conclusion_committee_reports",
      :to => "conclusion_committee_reports##{action}"
    get "follow_up_committee/#{action}",
      :as => "#{action}_follow_up_committee",
      :to => "follow_up_committee##{action}"
  end

  [
    'create_qa_indicators',
    'create_synthesis_report',
    'create_control_objective_stats',
    'create_process_control_stats',
    'create_rescheduled_being_implemented_weaknesses_report'
  ].each do |action|
    post "conclusion_committee_reports/#{action}",
      :as => "#{action}_conclusion_committee_reports",
      :to => "conclusion_committee_reports##{action}"
    post "follow_up_committee/#{action}",
      :as => "#{action}_follow_up_committee",
      :to => "follow_up_committee##{action}"
  end

  [
    'weaknesses_by_risk_report',
    'fixed_weaknesses_report',
    'nonconformities_report',
  ].each do |action|
    get "conclusion_committee_reports/#{action}",
      :as => "#{action}_conclusion_committee_reports",
      :to => "conclusion_committee_reports##{action}"
    get "follow_up_committee/#{action}",
      :as => "#{action}_follow_up_committee",
      :to => "follow_up_committee##{action}"
    get "conclusion_audit_reports/#{action}",
      :as => "#{action}_conclusion_audit_reports",
      :to => "conclusion_audit_reports##{action}"
    get "follow_up_audit/#{action}",
      :as => "#{action}_follow_up_audit",
      :to => "follow_up_audit##{action}"
  end

  [
    'create_weaknesses_by_risk_report',
    'create_fixed_weaknesses_report',
    'create_nonconformities_report'
  ].each do |action|
    post "conclusion_committee_reports/#{action}",
      :as => "#{action}_conclusion_committee_reports",
      :to => "conclusion_committee_reports##{action}"
    post "follow_up_committee/#{action}",
      :as => "#{action}_follow_up_committee",
      :to => "follow_up_committee##{action}"
    post "conclusion_audit_reports/#{action}",
      :as => "#{action}_conclusion_audit_reports",
      :to => "conclusion_audit_reports##{action}"
    post "follow_up_audit/#{action}",
      :as => "#{action}_follow_up_audit",
      :to => "follow_up_audit##{action}"
  end

  get "conclusion_audit_reports/cost_analysis",
    :as => 'cost_analysis_conclusion_audit_reports',
    :to => 'conclusion_audit_reports#cost_analysis'
  post "conclusion_audit_reports/create_cost_analysis",
    :as => 'create_cost_analysis_conclusion_audit_reports',
    :to => 'conclusion_audit_reports#create_cost_analysis'
  get 'conclusion_audit_reports/cost_analysis/detailed',
    :as => 'detailed_cost_analysis_conclusion_audit_reports',
    :to => 'conclusion_audit_reports#cost_analysis',
    :include_details => 1

  get 'follow_up_audit/cost_analysis',
    :as => 'cost_analysis_follow_up_audit',
    :to => 'follow_up_audit#cost_analysis'
  post 'follow_up_audit/create_cost_analysis',
    :as => 'create_cost_analysis_follow_up_audit',
    :to => 'follow_up_audit#create_cost_analysis'

  scope ':completed', :completed => /complete|incomplete/ do
    resources :findings, :except => [:destroy] do
      resources :costs

      member do
        get :follow_up_pdf
      end

      collection do
        get :export_to_pdf
        get :export_to_csv
        get :auto_complete_for_user
        get :auto_complete_for_finding_relation
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
      get :auto_complete_for_user
    end
  end

  resources :conclusion_draft_reviews, :except => [:destroy] do
    member do
      get :export_to_pdf
      get :compose_email
      patch :send_by_email
      get :download_work_papers
      get :score_sheet
      get :bundle
      post :create_bundle
    end

    collection do
      get :check_for_approval
      get :auto_complete_for_user
    end
  end

  resources :conclusion_final_reviews, :except => [:destroy] do
    member do
      get :export_to_pdf
      get :compose_email
      patch :send_by_email
      get :download_work_papers
      get :score_sheet
      get :bundle
      post :create_bundle
    end

    collection do
      get :auto_complete_for_user
      get :export_list_to_pdf
    end
  end

  resources :reviews do
    member do
      get :survey_pdf
      get :suggested_findings
      get :review_data
      get :weaknesses_and_oportunities
      get :download_work_papers
      get :estimated_amount
      get :procedure_control_data
    end

    collection do
      get :estimated_amount
      get :plan_item_data
      get :auto_complete_for_user
      get :auto_complete_for_finding
      get :auto_complete_for_procedure_control_subitem
    end
  end

  resources :weaknesses, :except => [:destroy] do
    resources :costs

    collection do
      get :auto_complete_for_user
      get :auto_complete_for_finding_relation
      get :auto_complete_for_control_objective_item
    end

    member do
      get :follow_up_pdf
      patch :undo_reiteration
    end
  end

  resources :nonconformities, :except => [:destroy] do
    resources :costs

    collection do
      get :auto_complete_for_user
      get :auto_complete_for_finding_relation
      get :auto_complete_for_control_objective_item
    end

    member do
      get :follow_up_pdf
      patch :undo_reiteration
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
      get :auto_complete_for_business_unit_business_unit_id
      get :auto_complete_for_user
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

  resources :oportunities, :except => [:destroy] do
    resources :costs

    member do
      get :follow_up_pdf
      patch :undo_reiteration
    end

    collection do
      get :auto_complete_for_user
      get :auto_complete_for_finding_relation
      get :auto_complete_for_control_objective_item
    end
  end

  resources :potential_nonconformities, :except => [:destroy] do
    resources :costs

    member do
      get :follow_up_pdf
      patch :undo_reiteration
    end

    collection do
      get :auto_complete_for_user
      get :auto_complete_for_finding_relation
      get :auto_complete_for_control_objective_item
    end
  end

  resources :organizations

  resources :roles

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
      get :auto_complete_for_user
      get :roles
      get :initial_roles
      get :reset_password
      post :send_password_reset
    end

    member do
      get :user_status
      get :user_status_without_graph
      get :logout
      get :edit_password
      patch :update_password
      get :edit_personal_data
      patch :update_personal_data
      patch :blank_password
      get :reassignment_edit
      patch :reassignment_update
      get :release_edit
      patch :release_update
    end
  end

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   get 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   get 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
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

  get 'private/:path', :to => 'file_models#download',
    :constraints => { :path => /.+/ }

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # get ':controller(/:action(/:id(.:format)))'

  # Any invalid route goes to the welcome page
  get '*a' => redirect('/welcome')
end
