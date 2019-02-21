Rails.application.routes.draw do
  post '/touch', to: 'touch#create', as: 'touch'

  # Sessions
  get    'login',    to: 'sessions#new',     as: 'login'
  post   'sessions', to: 'sessions#create',  as: 'sessions'
  delete 'logout',   to: 'sessions#destroy', as: 'logout'

  resources :settings, only: [:index, :show, :edit, :update]

  resources :benefits

  resources :opening_interviews
  resources :closing_interviews

  resources :risk_assessments do
    member do
      get :fetch_item
      get :new_item
      get :add_items
      patch :sort_by_risk
      post :merge_to_plan
    end

    collection do
      get :auto_complete_for_business_unit
      get :auto_complete_for_business_unit_type
      get :auto_complete_for_best_practice
    end
  end

  resources :risk_assessment_templates

  resources :readings, only: [:create]

  resources :documents do
    get :download, on: :member
    get :auto_complete_for_tagging, on: :collection
  end

  resources :questionnaires do
    resources :polls, only: [:index]
  end

  namespace :polls do
    resources :questionnaires, only: [:index]
    resources :answers, only: [:index]
    resources :business_units, only: [:index]
    resources :users, only: [:index]
  end

  resources :polls do
    collection do
      get :reports
      get :auto_complete_for_business_unit
    end
  end

  resources :e_mails, only: [:index, :show]

  resources :business_unit_types

  resources :groups

  resources :tags, only: [] do
    resources :documents, only: [:index]
  end

  scope ':kind', kind: /control_objective|document|finding|news|plan_item|review/ do
    resources :tags
  end

  resources :news do
    get :auto_complete_for_tagging, on: :collection
  end

  get 'welcome', as: 'welcome', to: 'welcome#index'
  get 'execution_reports', as: 'execution_reports', to: 'execution_reports#index'

  [
    'weaknesses_by_state_execution',
    'weaknesses_report',
    'detailed_management_report',
    'planned_cost_summary',
    'reviews_with_incomplete_work_papers_report'
  ].each do |action|
    get "execution_reports/#{action}", to: "execution_reports##{action}", as: action
  end

  [
    'create_weaknesses_by_state_execution',
    'create_detailed_management_report',
    'create_planned_cost_summary',
    'create_weaknesses_report'
  ].each do |action|
    post "execution_reports/#{action}", to: "execution_reports##{action}", as: action
  end

  %w[
    tagged_findings_report
  ].each do |action|
    get "execution_reports/#{action}", to: "execution_reports##{action}"
    post "execution_reports/create_#{action}", to: "execution_reports#create_#{action}"
  end

  resources :versions, only: [:index, :show]

  resources :notifications, only: [:index, :show, :edit, :update] do
    member do
      get :confirm
    end
  end

  get 'conclusion_reports', as: 'conclusion_reports', to: 'conclusion_reports#index'
  get 'follow_up_audit', as: 'follow_up_audit', to: 'follow_up_audit#index'

  [
    'synthesis_report',
    'review_stats_report',
    'review_scores_report',
    'review_score_details_report',
    'weaknesses_by_state',
    'weaknesses_by_risk',
    'weaknesses_by_risk_and_business_unit',
    'weaknesses_by_audit_type',
    'control_objective_stats',
    'control_objective_stats_by_review',
    'benefits',
    'process_control_stats',
    'qa_indicators',
    'weaknesses_by_business_unit',
    'weaknesses_by_month',
    'weaknesses_by_risk_report',
    'weaknesses_by_user',
    'weaknesses_current_situation',
    'fixed_weaknesses_report',
    'weaknesses_graphs',
    'auto_complete_for_business_unit',
    'auto_complete_for_process_control'
  ].each do |action|
    get "conclusion_reports/#{action}",
      as: "#{action}_conclusion_reports",
      to: "conclusion_reports##{action}"
    get "follow_up_audit/#{action}",
      as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
  end

  [
    'create_synthesis_report',
    'create_review_stats_report',
    'create_review_scores_report',
    'create_review_score_details_report',
    'create_weaknesses_by_state',
    'create_weaknesses_by_risk',
    'create_weaknesses_by_risk_and_business_unit',
    'create_weaknesses_by_audit_type',
    'create_control_objective_stats',
    'create_control_objective_stats_by_review',
    'create_benefits',
    'create_process_control_stats',
    'create_qa_indicators',
    'create_weaknesses_by_business_unit',
    'create_weaknesses_by_month',
    'create_weaknesses_by_risk_report',
    'create_weaknesses_by_user',
    'create_weaknesses_current_situation',
    'create_fixed_weaknesses_report'
  ].each do |action|
    post "conclusion_reports/#{action}",
      as: "#{action}_conclusion_reports",
      to: "conclusion_reports##{action}"
    post "follow_up_audit/#{action}",
      as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
  end

  get 'conclusion_reports/cost_analysis',
    as: 'cost_analysis_conclusion_reports',
    to: 'conclusion_reports#cost_analysis'
  post 'conclusion_reports/create_cost_analysis',
    as: 'create_cost_analysis_conclusion_reports',
    to: 'conclusion_reports#create_cost_analysis'
  get 'conclusion_reports/cost_analysis/detailed',
    as: 'detailed_cost_analysis_conclusion_reports',
    to: 'conclusion_reports#cost_analysis',
    include_details: 1

  get 'conclusion_reports/cost_summary',
    as: 'cost_summary_conclusion_reports',
    to: 'conclusion_reports#cost_summary'
  post 'conclusion_reports/create_cost_summary',
    as: 'create_cost_summary_conclusion_reports',
    to: 'conclusion_reports#create_cost_summary'

  %w[
    follow_up_cost_analysis
    weaknesses_report
    weaknesses_evolution
    weaknesses_list
    weaknesses_brief
    tagged_findings_report
  ].each do |action|
    get "follow_up_audit/#{action}",
      as: "#{action}_follow_up_audit",
      to: "follow_up_audit##{action}"
    post "follow_up_audit/create_#{action}",
      as: "create_#{action}_follow_up_audit",
      to: "follow_up_audit#create_#{action}"
  end

  scope ':completed', completed: /complete|incomplete/ do
    resources :findings, except: [:destroy] do
      resources :costs

      get :follow_up_pdf, on: :member, to: 'findings/follow_up_pdf#show'

      collection do
        get :export_to_pdf
        get :export_to_csv
        get :auto_complete_for_tagging
        get :auto_complete_for_finding_relation
      end
    end
  end

  namespace :workflows do
    resources :users, only: [:index]
  end

  resources :workflows do
    get :export_to_pdf, on: :member

    collection do
      get :estimated_amount
      get :reviews_for_period
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

    collection do
      get :check_for_approval
      get :corrective_actions_update
    end
  end

  namespace :conclusion_final_reviews do
    resources :users, only: [:index]
  end

  resources :conclusion_final_reviews do
    member do
      get :export_to_pdf
      get :compose_email
      patch :send_by_email
      get :download_work_papers
      get :score_sheet
      post :create_bundle
    end

    get :export_list_to_pdf, on: :collection
  end

  namespace :reviews do
    resources :users, only: [:index]
  end

  resources :reviews do
    member do
      get :survey_pdf
      get :suggested_findings
      get :suggested_process_control_findings
      get :past_implemented_audited_findings
      get :weaknesses_and_oportunities
      get :download_work_papers
      get :estimated_amount
      get :excluded_control_objectives
      patch :finished_work_papers
      patch :recode_findings
      patch :recode_weaknesses_by_risk
      patch :recode_weaknesses_by_repetition_and_risk
      patch :recode_weaknesses_by_control_objective_order
      patch :reorder
      patch :reset_control_objective_name
    end

    collection do
      get :estimated_amount
      get :plan_item_refresh
      get :assignment_type_refresh
      get :plan_item_data
      get :auto_complete_for_finding
      get :auto_complete_for_best_practice
      get :auto_complete_for_process_control
      get :auto_complete_for_control_objective
      get :auto_complete_for_tagging
      get :next_identification_number
    end
  end

  namespace :weaknesses do
    resources :users, only: [:index]
  end

  resources :weaknesses, except: [:destroy] do
    resources :costs

    collection do
      get :auto_complete_for_tagging
      get :auto_complete_for_finding_relation
      get :auto_complete_for_control_objective_item
      get :auto_complete_for_weakness_template
      get :state_changed
      get :weakness_template_changed
    end

    member do
      patch :undo_reiteration
    end
  end

  resources :weakness_templates do
    get :auto_complete_for_control_objective, on: :collection
  end

  resources :control_objective_items do
    get :suggest_next_work_paper_code, on: :member

    collection do
      get :auto_complete_for_business_unit
      get :auto_complete_for_business_unit_type
    end
  end

  namespace :plans do
    resources :users, only: [:index]
  end

  resources :plans do
    resources :plan_items, only: [:new, :edit]

    member do
      get :calendar, to: 'plans/calendar#show'
      get :resources, to: 'plans/resources#show'
      get :stats, to: 'plans/stats#show'
    end

    collection do
      get :auto_complete_for_business_unit
      get :auto_complete_for_tagging
    end
  end

  resources :resource_classes

  resources :control_objectives, only: [:index, :show]

  resources :best_practices do
    resources :process_controls, only: [:new, :edit]

    resources :control_objectives, only: [] do
      get :download, on: :member, controller: 'best_practices/control_objectives'
    end

    get :auto_complete_for_tagging, on: :collection
  end

  resources :periods

  namespace :oportunities do
    resources :users, only: [:index]
  end

  resources :oportunities, except: [:destroy] do
    resources :costs

    member do
      patch :undo_reiteration
    end

    collection do
      get :auto_complete_for_tagging
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
    resources :completions, only: [:index]
    resources :passwords, except: [:index, :show, :destroy]
    resources :profiles, only: [:edit, :update]
    resources :reassignments, only: [:edit, :update]
    resources :registrations, only: [:new, :create]
    resources :registration_roles, only: [:index]
    resources :releases, only: [:edit, :update]
    resources :roles, only: [:index]
    resources :status, only: [:index, :show, :create, :destroy]
    resources :imports, only: [:new, :create]
  end

  resources :users

  root 'sessions#new'

  get 'private/:path', to: 'file_models#download', constraints: { path: /.+/ }
end
