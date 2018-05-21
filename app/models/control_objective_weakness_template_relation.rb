class ControlObjectiveWeaknessTemplateRelation < ApplicationRecord
  unless ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
    self.table_name = 'co_weakness_template_relations'
  end

  include Auditable

  validates :control_objective, presence: true

  belongs_to :control_objective
  belongs_to :weakness_template
end
