Rails.application.routes.draw do
  get '/users/login', to: redirect('/') # _Backward compatibility_

  # Sessions
  get    'login',    to: 'sessions#new',     as: 'login'
  post   'sessions', to: 'sessions#create',  as: 'sessions'
  delete 'logout',   to: 'sessions#destroy', as: 'logout'

  resources :settings, only: [:index, :show, :edit, :update]

  resources :questionnaires

  namespace :polls do
    resources :questionnaires, only: [:index]
    resources :answers, only: [:index]
    resources :business_units, only: [:index]
    resources :users, only: [:index]
  end

  resources :polls do
    collection do
      get :import_csv_customers
      post :send_csv_polls
      get :reports
    end
  end

  resources :e_mails, only: [:index, :show]

  resources :business_unit_types

  resources :fortresses do
    resources :costs

    collection do
      get :auto_complete_for_user
      get :auto_complete_for_control_objective_item
    end
  end

  resources :groups

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

  resources :versions, only: [:index, :show]

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
      as: "#{action}_conclusion_management_reports",
      to: "conclusion_management_reports##{action}"
    post "conclusion_audit_reports/#{action}",
      as: "#{action}_conclusion_audit_reports",
      to: "conclusion_audit_reports##{action}"
    post "follow_up_management/#{action}",
      as: "#{action}_follow_up_management",
      to: "follow_up_management##{action}"
    post "follow_up_audit/#{action}", as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
  end

  [
    'qa_indicators',
    'synthesis_report',
    'control_objective_stats',
    'process_control_stats',
    'rescheduled_being_implemented_weaknesses_report'
  ].each do |action|
    get "conclusion_committee_reports/#{action}",
      as: "#{action}_conclusion_committee_reports",
      to: "conclusion_committee_reports##{action}"
    get "follow_up_committee/#{action}",
      as: "#{action}_follow_up_committee",
      to: "follow_up_committee##{action}"
  end

  [
    'create_qa_indicators',
    'create_synthesis_report',
    'create_control_objective_stats',
    'create_process_control_stats',
    'create_rescheduled_being_implemented_weaknesses_report'
  ].each do |action|
    post "conclusion_committee_reports/#{action}",
      as: "#{action}_conclusion_committee_reports",
      to: "conclusion_committee_reports##{action}"
    post "follow_up_committee/#{action}",
      as: "#{action}_follow_up_committee",
      to: "follow_up_committee##{action}"
  end

  [
    'weaknesses_by_risk_report',
    'fixed_weaknesses_report',
    'nonconformities_report',
  ].each do |action|
    get "conclusion_committee_reports/#{action}",
      as: "#{action}_conclusion_committee_reports",
      to: "conclusion_committee_reports##{action}"
    get "follow_up_committee/#{action}",
      as: "#{action}_follow_up_committee",
      to: "follow_up_committee##{action}"
    get "conclusion_audit_reports/#{action}",
      as: "#{action}_conclusion_audit_reports",
      to: "conclusion_audit_reports##{action}"
    get "follow_up_audit/#{action}",
      as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
  end

  [
    'create_weaknesses_by_risk_report',
    'create_fixed_weaknesses_report',
    'create_nonconformities_report'
  ].each do |action|
    post "conclusion_committee_reports/#{action}",
      as: "#{action}_conclusion_committee_reports",
      to: "conclusion_committee_reports##{action}"
    post "follow_up_committee/#{action}",
      as: "#{action}_follow_up_committee",
      to: "follow_up_committee##{action}"
    post "conclusion_audit_reports/#{action}",
      as: "#{action}_conclusion_audit_reports",
      to: "conclusion_audit_reports##{action}"
    post "follow_up_audit/#{action}",
      as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
  end

  get "conclusion_audit_reports/cost_analysis",
    as: 'cost_analysis_conclusion_audit_reports',
    to: 'conclusion_audit_reports#cost_analysis'
  post "conclusion_audit_reports/create_cost_analysis",
    as: 'create_cost_analysis_conclusion_audit_reports',
    to: 'conclusion_audit_reports#create_cost_analysis'
  get 'conclusion_audit_reports/cost_analysis/detailed',
    as: 'detailed_cost_analysis_conclusion_audit_reports',
    to: 'conclusion_audit_reports#cost_analysis',
    include_details: 1

  get 'follow_up_audit/follow_up_cost_analysis',
    as: 'follow_up_cost_analysis_follow_up_audit',
    to: 'follow_up_audit#follow_up_cost_analysis'
  post 'follow_up_audit/create_follow_up_cost_analysis',
    as: 'create_follow_up_cost_analysis_follow_up_audit',
    to: 'follow_up_audit#create_follow_up_cost_analysis'

  scope ':completed', completed: /complete|incomplete/ do
    resources :findings, except: [:destroy] do
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

  namespace :conclusion_draft_reviews do
    resources :users, only: [:index]
  end

  resources :conclusion_draft_reviews, except: [:destroy] do
    member do
      get :export_to_pdf
      get :compose_email
      patch :send_by_email
      get :download_work_papers
      get :score_sheet
      post :create_bundle
    end

    get :check_for_approval, on: :collection
  end

  resources :conclusion_final_reviews, except: [:destroy] do
    member do
      get :export_to_pdf
      get :compose_email
      patch :send_by_email
      get :download_work_papers
      get :score_sheet
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

  resources :weaknesses, except: [:destroy] do
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

  resources :nonconformities, except: [:destroy] do
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

  resources :oportunities, except: [:destroy] do
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

  resources :potential_nonconformities, except: [:destroy] do
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

  resources :error_records, only: [:index, :show]

  resources :login_records, only: [:index, :show] do
    get :choose, on: :collection
  end

  namespace :users do
    resources :passwords, except: [:index, :show, :destroy]
    resources :profiles, only: [:edit, :update]
    resources :reassignments, only: [:edit, :update]
    resources :registrations, only: [:new, :create]
    resources :registration_roles, only: [:index]
    resources :releases, only: [:edit, :update]
    resources :roles, only: [:index]
    resources :status, only: [:show]
  end

  resources :users do
    collection do
      get :export_to_pdf
      get :auto_complete_for_user
    end
  end

  root 'sessions#new'

  get 'private/:path', to: 'file_models#download', constraints: { path: /.+/ }
end
