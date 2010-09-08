ActionController::Routing::Routes.draw do |map|
  map.resources :business_unit_types

  map.resources :groups

  map.resources :detracts, :only => [:index, :show, :new, :create], :member => {
    :show_last_detractors => :get
  }

  map.resources :inline_helps

  map.welcome 'welcome', :controller => 'welcome', :action => 'index'
  
  map.execution_reports 'execution_reports', :controller => 'execution_reports',
    :action => 'index'

  [
    'weaknesses_by_state',
    'create_weaknesses_by_state',
    'detailed_management_report',
    'create_detailed_management_report'
  ].each do |action|
    map.named_route action, "execution_reports/#{action}",
      :controller => 'execution_reports', :action => action
  end

  map.resources :versions, :collection => {
    :security_changes_report => :get
  }

  map.resources :help_items

  map.resources :help_contents, :member => {
    :show_content => :get
  }, :collection => {
    :show_content => :get
  }

  map.resources :notifications, :member => {
    :confirm => :get
  }

  map.resources :backups, :collection => {
    :restore_setup => :get,
    :restore => :post
  }

  map.conclusion_audit_reports 'conclusion_audit_reports',
    :controller => 'conclusion_audit_reports', :action => 'index'

  map.conclusion_committee_reports 'conclusion_committee_reports',
    :controller => 'conclusion_committee_reports', :action => 'index'

  map.conclusion_management_reports 'conclusion_management_reports',
    :controller => 'conclusion_management_reports', :action => 'index'

  map.follow_up_audit 'follow_up_audit',
    :controller => 'follow_up_audit', :action => 'index'

  map.follow_up_committee 'follow_up_committee',
    :controller => 'follow_up_committee', :action => 'index'

  map.follow_up_management 'follow_up_management',
    :controller => 'follow_up_management', :action => 'index'

  [
    'weaknesses_by_state', 'create_weaknesses_by_state',
    'weaknesses_by_risk', 'create_weaknesses_by_risk',
    'weaknesses_by_audit_type', 'create_weaknesses_by_audit_type'
  ].each do |action|
    map.named_route "#{action}_conclusion_management_reports",
      "conclusion_management_reports/#{action}",
      :controller => 'conclusion_management_reports', :action => action
    map.named_route "#{action}_conclusion_audit_reports",
      "conclusion_audit_reports/#{action}",
      :controller => 'conclusion_audit_reports', :action => action
    map.named_route "#{action}_follow_up_management",
      "follow_up_management/#{action}", :controller => 'follow_up_management',
      :action => action
    map.named_route "#{action}_follow_up_audit",
      "follow_up_audit/#{action}", :controller => 'follow_up_audit',
      :action => action
  end

  [
    'cost_analysis', 'create_cost_analysis',
    'synthesis_report', 'create_synthesis_report',
    'weaknesses_by_state', 'create_weaknesses_by_state',
    'weaknesses_by_risk', 'create_weaknesses_by_risk',
    'weaknesses_by_audit_type', 'create_weaknesses_by_audit_type'
  ].each do |action|
    map.named_route "#{action}_conclusion_committee_reports",
      "conclusion_committee_reports/#{action}",
      :controller => 'conclusion_committee_reports', :action => action
    map.named_route "#{action}_follow_up_committee",
      "follow_up_committee/#{action}", :controller => 'follow_up_committee',
      :action => action
  end

  map.named_route 'cost_analysis_conclusion_committee_reports',
    "conclusion_committee_reports/cost_analysis",
    :controller => 'conclusion_committee_reports', :action => 'cost_analysis'
  map.named_route 'detailed_cost_analysis_conclusion_committee_reports',
    "conclusion_committee_reports/cost_analysis/detailed",
    :controller => 'conclusion_committee_reports', :action => 'cost_analysis',
    :include_details => 1

  map.named_route 'cost_analysis_follow_up_committee',
    "follow_up_committee/cost_analysis",
    :controller => 'follow_up_committee', :action => 'cost_analysis'

  map.resources :findings, :has_many => :costs, :member => {
    :follow_up_pdf => :get,
    :auto_complete_for_user => :post,
    :auto_complete_for_finding_relation => :post
  }, :collection => {
    :export_to_pdf => :get
  }, :path_prefix => ':completed',
    :requirements => {:completed => /complete|incomplete/}

  map.resources :workflows, :member => {
    :export_to_pdf => :get,
  }, :collection => {
    :estimated_amount => :get,
    :reviews_for_period => :get
  }

  map.resources :conclusion_draft_reviews, :member => {
    :export_to_pdf => :get,
    :auto_complete_for_user => :post,
    :compose_email => :get,
    :send_by_email => :put,
    :download_work_papers => :get,
    :score_sheet => :get,
    :bundle => :get,
    :create_bundle => :post
  }

  map.resources :conclusion_final_reviews, :member => {
    :export_to_pdf => :get,
    :auto_complete_for_user => :post,
    :compose_email => :get,
    :send_by_email => :put,
    :download_work_papers => :get,
    :score_sheet => :get,
    :bundle => :get,
    :create_bundle => :post
  }, :collection => {
    :export_list_to_pdf => :get
  }

  map.resources :reviews, :member => {
    :survey_pdf => :get,
    :review_data => :get,
    :weaknesses_and_oportunities => :get,
    :download_work_papers => :get,
    :estimated_amount => :get,
    :plan_item_data => :get,
    :procedure_control_data => :get
  }, :collection => {
    :estimated_amount => :get,
    :auto_complete_for_user => :post,
    :auto_complete_for_procedure_control_subitem => :post
  }

  map.resources :weaknesses, :has_many => :costs, :member => {
    :follow_up_pdf => :get,
    :auto_complete_for_user => :post,
    :auto_complete_for_finding_relation => :post
  }

  map.resources :control_objective_items, :member => {
    :suggest_next_work_paper_code => :get
  }

  map.resources :plans, :member => {
    :export_to_pdf => :get,
    :auto_complete_for_business_unit_business_unit_id => :post
  }

  map.resources :resource_classes

  map.resources :procedure_controls, :member => {
    :export_to_pdf => :get
  }, :collection => {
    :get_control_objective => :get,
    :get_control_objectives => :get,
    :get_process_controls => :get
  }

  map.resources :best_practices

  map.resources :periods

  map.resources :oportunities, :has_many => :costs, :member => {
    :follow_up_pdf => :get,
    :auto_complete_for_user => :post,
    :auto_complete_for_finding_relation => :post
  }

  map.resources :organizations

  map.resources :roles

  map.resources :parameters, :path_prefix => ':type',
    :requirements => {:type => /admin|security/}

  map.resources :error_records, :collection => {
    :export_to_pdf => :get
  }

  map.resources :login_records, :collection => {
    :choose => :get,
    :export_to_pdf => :get
  }

  map.resources :users, :collection => {
    :login => :get,
    :create_session => :post,
    :new_initial => :get,
    :create_initial => :post,
    :export_to_pdf => :get,
    :auto_complete_for_user => :post,
    :roles => :get,
    :initial_roles => :get
  }, :member => {
    :logout => :get,
    :edit_password => :get,
    :update_password => :put,
    :edit_personal_data => :get,
    :update_personal_data => :put,
    :blank_password => :put,
    :reassignment_edit => :get,
    :reassignment_update => :put,
    :release_edit => :get,
    :release_update => :put
  }

  # The priority is based upon order of creation: first created -> highest priority.

  # Sample of regular route:
  #   map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   map.resources :products

  # Sample resource route with options:
  #   map.resources :products, :member => { :short => :get, :toggle => :post }, :collection => { :sold => :get }

  # Sample resource route with sub-resources:
  #   map.resources :products, :has_many => [ :comments, :sales ], :has_one => :seller
  
  # Sample resource route with more complex sub-resources
  #   map.resources :products do |products|
  #     products.resources :comments
  #     products.resources :sales, :collection => { :recent => :get }
  #   end

  # Sample resource route within a namespace:
  #   map.namespace :admin do |admin|
  #     # Directs /admin/products/* to Admin::ProductsController (app/controllers/admin/products_controller.rb)
  #     admin.resources :products
  #   end

  # You can have the root of your site routed with map.root -- just remember to delete public/index.html.
  map.root :controller => 'users', :action => 'login'

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  map.connect 'private/:path', :controller => 'file_models',
    :action => 'download', :path => /.+/
  map.connect ':controller/page/:page', :page => /\d+/
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'
end