class AddAuditRecomendationsToWeaknessTemplate < ActiveRecord::Migration[6.0]
  def change
    add_column :weakness_templates, :audit_recommendations, :text
  end
end
