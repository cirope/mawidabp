# Menú del auditado
APP_AUDITED_MENU_ITEMS = [
  # ADMINISTRACIÓN
  MenuItem.new(
    :administration,
    :order => 1,
    :url => '#menu_administration',
    :children => [
      MenuItem.new(
        :detracts,
        :order => 1,
        :controllers => :detracts,
        :url => {:controller => :detracts}
      )
    ]
  ),
  MenuItem.new(
    :follow_up,
    :order => 1,
    :url => '#menu_follow_up',
    :children => [
      MenuItem.new(
        :pending_findings,
        :order => 1,
        :controllers => :findings,
        :extra_conditions => "params[:completed] == 'incomplete'",
        :url => {:controller => :findings, :completed => :incomplete}
      ),
      MenuItem.new(
        :complete_findings,
        :order => 2,
        :controllers => :findings,
        :extra_conditions => "params[:completed] == 'complete'",
        :url => {:controller => :findings, :completed => :complete}
      ),
      MenuItem.new(
        :notifications,
        :order => 3,
        :controllers => :notifications,
        :url => {:controller => :notifications}
      )
    ]
  ),
  MenuItem.new(
    :help,
    :order => 6,
    :url => {:controller => :help_contents, :action => :show_content},
    :controllers => [:help_contents, :help_items, :inline_helps],
    :exclude_from_privileges => true
  )
].freeze

# Menú del auditor
APP_AUDITOR_MENU_ITEMS = [
  # ADMINISTRACIÓN
  MenuItem.new(
    :administration,
    :order => 1,
    :url => '#menu_administration',
    :children => [
      MenuItem.new(
        :organization,
        :order => 1,
        :url => '#menu_administration_organization',
        :class => :menu_item_2,
        :children => [
          MenuItem.new(
            :management,
            :order => 1,
            :controllers => :organizations,
            :extra_conditions => "!['edit_business_units', 'update_business_units'].include?(params[:action])",
            :url => {:controller => :organizations}
          ),
          MenuItem.new(
            :business_units,
            :order => 2,
            :controllers => :organizations,
            :extra_conditions => "['edit_business_units', 'update_business_units'].include?(params[:action])",
            :url => {:controller => :organizations, :action => :edit_business_units}
          )
        ]
      ),
      MenuItem.new(
        :security,
        :order => 2,
        :url => '#menu_administration_security',
        :class => :menu_item_2,
        :children => [
          MenuItem.new(
            :parameters,
            :order => 1,
            :controllers => :parameters,
            :extra_conditions => "params[:type] == 'security'",
            :url => {:controller => :parameters, :type => :security}
          ),
          MenuItem.new(
            :reports,
            :order => 2,
            :controllers => [:error_records, :login_records, :versions],
            :url => {:controller => :login_records, :action => :choose}
          ),
          MenuItem.new(
            :users,
            :order => 3,
            :controllers => :users,
            :url => {:controller => :users}
          ),
          MenuItem.new(
            :roles,
            :order => 4,
            :controllers => :roles,
            :url => {:controller => :roles}
          )
        ]
      ),
      MenuItem.new(
        :best_practices,
        :order => 3,
        :controllers => :best_practices,
        :url => {:controller => :best_practices}
      ),
      MenuItem.new(
        :parameters,
        :order => 4,
        :controllers => :parameters,
        :extra_conditions => "params[:type] == 'admin'",
        :url => {:controller => :parameters, :type => :admin}
      ),
      MenuItem.new(
        :backups,
        :order => 5,
        :controllers => :backups,
        :url => {:controller => :backups}
      ),
      MenuItem.new(
        :detracts,
        :order => 6,
        :controllers => :detracts,
        :url => {:controller => :detracts}
      )
    ]
  ),
  # PLANIFICACIÓN
  MenuItem.new(
    :planning,
    :order => 2,
    :url => '#menu_planning',
    :children => [
      MenuItem.new(
        :resources,
        :order => 1,
        :controllers => :resource_classes,
        :url => {:controller => :resource_classes}
      ),
      MenuItem.new(
        :periods,
        :order => 2,
        :controllers => :periods,
        :url => {:controller => :periods}
      ),
      MenuItem.new(
        :audit,
        :order => 3,
        :url => '#menu_planning_audit',
        :class => :menu_item_2,
        :children => [
          MenuItem.new(
            :plans,
            :order => 1,
            :controllers => :plans,
            :url => {:controller => :plans}
          ),
          MenuItem.new(
            :procedure_controls,
            :order => 2,
            :controllers => :procedure_controls,
            :url => {:controller => :procedure_controls}
          )
        ]
      )
    ]
  ),
  # EJECUCIÓN
  MenuItem.new(
    :execution,
    :order => 3,
    :url => '#menu_execution',
    :children => [
      MenuItem.new(
        :reviews,
        :order => 1,
        :controllers => :reviews,
        :url => {:controller => :reviews}
      ),
      MenuItem.new(
        :workflows,
        :order => 2,
        :controllers => :workflows,
        :url => {:controller => :workflows}
      ),
      MenuItem.new(
        :control_objectives,
        :order => 3,
        :controllers => :control_objective_items,
        :url => {:controller => :control_objective_items}
      ),
      MenuItem.new(
        :weaknesses,
        :order => 4,
        :controllers => :weaknesses,
        :url => {:controller => :weaknesses}
      ),
      MenuItem.new(
        :oportunities,
        :order => 5,
        :controllers => :oportunities,
        :url => {:controller => :oportunities}
      ),
      MenuItem.new(
        :reports,
        :order => 6,
        :controllers => :execution_reports,
        :url => {:controller => :execution_reports}
      )
    ]
  ),
  # CONCLUSIÓN
  MenuItem.new(
    :conclusion,
    :order => 4,
    :url => '#menu_conclusion',
    :children => [
      MenuItem.new(
        :draft_reviews,
        :order => 1,
        :controllers => :conclusion_draft_reviews,
        :url => {:controller => :conclusion_draft_reviews}
      ),
      MenuItem.new(
        :final_reviews,
        :order => 2,
        :controllers => :conclusion_final_reviews,
        :url => {:controller => :conclusion_final_reviews}
      ),
      MenuItem.new(
        :reports,
        :order => 3,
        :url => '#menu_conclusion_reports',
        :class => :menu_item_2,
        :children => [
          MenuItem.new(
            :audit,
            :order => 1,
            :controllers => :conclusion_audit_reports,
            :url => {:controller => :conclusion_audit_reports}
          ),
          MenuItem.new(
            :committee,
            :order => 2,
            :controllers => :conclusion_committee_reports,
            :url => {:controller => :conclusion_committee_reports}
          ),
          MenuItem.new(
            :management,
            :order => 3,
            :controllers => :conclusion_management_reports,
            :url => {:controller => :conclusion_management_reports}
          )
        ]
      )
    ]
  ),
  # SEGUIMIENTO
  MenuItem.new(
    :follow_up,
    :order => 5,
    :url => '#menu_follow_up',
    :children => [
      MenuItem.new(
        :pending_findings,
        :order => 1,
        :controllers => :findings,
        :extra_conditions => "params[:completed] == 'incomplete'",
        :url => {:controller => :findings, :completed => :incomplete}
      ),
      MenuItem.new(
        :complete_findings,
        :order => 2,
        :controllers => :findings,
        :extra_conditions => "params[:completed] == 'complete'",
        :url => {:controller => :findings, :completed => :complete}
      ),
      MenuItem.new(
        :notifications,
        :order => 3,
        :controllers => :notifications,
        :url => {:controller => :notifications}
      ),
      MenuItem.new(
        :reports,
        :order => 4,
        :url => '#menu_follow_up_reports',
        :class => :menu_item_2,
        :children => [
          MenuItem.new(
            :audit,
            :order => 1,
            :controllers => :follow_up_audit,
            :url => {:controller => :follow_up_audit}
          ),
          MenuItem.new(
            :committee,
            :order => 2,
            :controllers => :follow_up_committee,
            :url => {:controller => :follow_up_committee}
          ),
          MenuItem.new(
            :management,
            :order => 3,
            :controllers => :follow_up_management,
            :url => {:controller => :follow_up_management}
          )
        ]
      )
    ]
  ),
  # AYUDA
  MenuItem.new(
    :help,
    :order => 6,
    :url => {:controller => :help_contents, :action => :show_content},
    :controllers => [:help_contents, :help_items, :inline_helps],
    :exclude_from_privileges => true
  )
].freeze

APP_AUDITOR_MODULES = APP_AUDITOR_MENU_ITEMS.map do |menu_item|
  menu_item.submenu_names
end.flatten.freeze

APP_AUDITED_MODULES = APP_AUDITED_MENU_ITEMS.map do |menu_item|
  menu_item.submenu_names
end.flatten.freeze

APP_MODULES = (APP_AUDITOR_MODULES | APP_AUDITED_MODULES).freeze

ALLOWED_MODULES_BY_TYPE = {
  :admin => APP_AUDITOR_MODULES,
  :manager => APP_AUDITOR_MODULES,
  :supervisor => APP_AUDITOR_MODULES,
  :auditor_senior => APP_AUDITOR_MODULES,
  :auditor_junior => APP_AUDITOR_MODULES,
  :committee => APP_AUDITOR_MODULES,
  :audited => APP_AUDITED_MODULES,
  :executive_manager => APP_AUDITOR_MODULES
}