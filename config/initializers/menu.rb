# Menú del auditado
APP_AUDITED_MENU_ITEMS = [
  MenuItem.new(
    :follow_up,
    order: 1,
    children: [
      MenuItem.new(
        :pending_findings,
        order: 1,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'incomplete'",
        url: { controller: '/findings', completed: :incomplete }
      ),
      MenuItem.new(
        :complete_findings,
        order: 2,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'complete'",
        url: { controller: '/findings', completed: :complete }
      ),
      MenuItem.new(
        :notifications,
        order: 3,
        controllers: :notifications,
        url: { controller: '/notifications' }
      )
    ]
  )
].freeze

# Menú del auditor
APP_AUDITOR_MENU_ITEMS = [
  # ADMINISTRACIÓN
  MenuItem.new(
    :administration,
    order: 1,
    children: [
      MenuItem.new(
        :organization,
        order: 1,
        url: { controller: '/organizations' },
        children: [
          MenuItem.new(
            :management,
            order: 1,
            controllers: :organizations,
            url: { controller: '/organizations' }
          ),
          MenuItem.new(
            :business_units,
            order: 2,
            controllers: :business_unit_types,
            url: { controller: '/business_unit_types' }
          )
        ]
      ),
      MenuItem.new(
        :security,
        order: 2,
        url: { controller: '/users' },
        children: [
          MenuItem.new(
            :users,
            order: 1,
            controllers: :users,
            url: { controller: '/users' }
          ),
          MenuItem.new(
            :reports,
            order: 2,
            controllers: [:error_records, :login_records, :versions],
            url: { controller: '/login_records', action: :choose }
          ),
          MenuItem.new(
            :roles,
            order: 3,
            controllers: :roles,
            url: { controller: '/roles' }
          )
        ]
      ),
      MenuItem.new(
        :best_practices,
        order: 3,
        url: { controller: '/best_practices' },
        children: [
          MenuItem.new(
            :best_practices,
            order: 1,
            controllers: :best_practices,
            url: { controller: '/best_practices' }
          ),
          MenuItem.new(
            :control_objectives,
            order: 1,
            controllers: :control_objectives,
            url: { controller: '/control_objectives' }
          )
        ]
      ),
      MenuItem.new(
        :settings,
        order: 4,
        controllers: :settings,
        url: { controller: '/settings' }
      ),
      MenuItem.new(
        :weakness_templates,
        order: 5,
        controllers: :weakness_templates,
        url: { controller: '/weakness_templates' }
      ),
      MenuItem.new(
        :risk_assessment_templates,
        order: 6,
        controllers: :risk_assessment_templates,
        url: { controller: '/risk_assessment_templates' }
      ),
      MenuItem.new(
        :tags,
        order: 7,
        controllers: :tags,
        url: { controller: '/tags', kind: 'finding' }
      ),
      MenuItem.new(
        :documents,
        order: 8,
        controllers: :documents,
        url: { controller: '/documents' }
      ),
      MenuItem.new(
        :news,
        order: 9,
        controllers: :news,
        url: { controller: '/news' }
      ),
      MenuItem.new(
        :benefits,
        order: 10,
        controllers: :benefits,
        url: { controller: '/benefits' }
      ),
      MenuItem.new(
        :e_mails,
        order: 11,
        controllers: :e_mails,
        url: { controller: '/e_mails' }
      ),
      MenuItem.new(
        :questionnaires,
        order: 12,
        url: { controller: '/questionnaires' },
        children: [
          MenuItem.new(
            :definition,
            order: 1,
            controllers: :questionnaires,
            url: { controller: '/questionnaires' }
          ),
          MenuItem.new(
            :polls,
            order: 2,
            controllers: :polls,
            url: { controller: '/polls' }
          ),
          MenuItem.new(
            :reports,
            order: 3,
            controllers: :polls,
            url: { controller: '/polls', action: :reports }
          )
        ]
      )
    ]
  ),
  # PLANIFICACIÓN
  MenuItem.new(
    :planning,
    order: 2,
    children: [
      MenuItem.new(
        :resources,
        order: 1,
        controllers: :resource_classes,
        url: { controller: '/resource_classes' }
      ),
      MenuItem.new(
        :periods,
        order: 2,
        controllers: :periods,
        url: { controller: '/periods' }
      ),
      MenuItem.new(
        :risk_assessments,
        order: 3,
        controllers: :risk_assessments,
        url: { controller: '/risk_assessments' }
      ),
      MenuItem.new(
        :plans,
        order: 4,
        controllers: :plans,
        url: { controller: '/plans' }
      )
    ]
  ),
  # EJECUCIÓN
  MenuItem.new(
    :execution,
    order: 3,
    children: [
      MenuItem.new(
        :reviews,
        order: 1,
        controllers: :reviews,
        url: { controller: '/reviews' }
      ),
      MenuItem.new(
        :workflows,
        order: 2,
        controllers: :workflows,
        url: { controller: '/workflows' }
      ),
      MenuItem.new(
        :control_objectives,
        order: 3,
        controllers: :control_objective_items,
        url: { controller: '/control_objective_items' }
      ),
      MenuItem.new(
        :weaknesses,
        order: 4,
        controllers: :weaknesses,
        url: { controller: '/weaknesses' }
      ),
      (MenuItem.new(
        :oportunities,
        order: 5,
        controllers: :oportunities,
        url: { controller: '/oportunities' }
      ) unless HIDE_OPORTUNITIES),
      MenuItem.new(
        :interviews,
        order: 6,
        url: { controller: '/opening_interviews' },
        children: [
          MenuItem.new(
            :opening_interviews,
            order: 1,
            controllers: :opening_interviews,
            url: { controller: '/opening_interviews' }
          )
        ]
      ),
      MenuItem.new(
        :reports,
        order: 6,
        controllers: :execution_reports,
        url: { controller: '/execution_reports' }
      )
    ].compact
  ),
  # CONCLUSIÓN
  MenuItem.new(
    :conclusion,
    order: 4,
    children: [
      MenuItem.new(
        :draft_reviews,
        order: 1,
        controllers: :conclusion_draft_reviews,
        url: { controller: '/conclusion_draft_reviews' }
      ),
      MenuItem.new(
        :final_reviews,
        order: 2,
        controllers: :conclusion_final_reviews,
        url: { controller: '/conclusion_final_reviews' }
      ),
      MenuItem.new(
        :reports,
        order: 3,
        controllers: :conclusion_reports,
        url: { controller: '/conclusion_reports' }
      )
    ]
  ),
  # SEGUIMIENTO
  MenuItem.new(
    :follow_up,
    order: 5,
    children: [
      MenuItem.new(
        :pending_findings,
        order: 1,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'incomplete'",
        url: { controller: '/findings', completed: :incomplete }
      ),
      MenuItem.new(
        :complete_findings,
        order: 2,
        controllers: :findings,
        extra_conditions: "params[:completed] == 'complete'",
        url: { controller: '/findings', completed: :complete }
      ),
      MenuItem.new(
        :notifications,
        order: 3,
        controllers: :notifications,
        url: { controller: '/notifications' }
      ),
      MenuItem.new(
        :reports,
        order: 4,
        controllers: :follow_up_audit,
        url: { controller: '/follow_up_audit' }
      )
    ]
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
  admin: APP_AUDITOR_MODULES,
  manager: APP_AUDITOR_MODULES,
  supervisor: APP_AUDITOR_MODULES,
  auditor_senior: APP_AUDITOR_MODULES,
  auditor_junior: APP_AUDITOR_MODULES,
  committee: APP_AUDITOR_MODULES,
  audited: APP_AUDITED_MODULES,
  executive_manager: APP_AUDITOR_MODULES
}
