class AddOrganizationRefToModels < ActiveRecord::Migration[4.2]
  def change
    add_reference :conclusion_reviews, :organization, index: true
    add_reference :control_objective_items, :organization, index: true
    add_reference :findings, :organization, index: true
    add_reference :plans, :organization, index: true
    add_reference :procedure_controls, :organization, index: true
    add_reference :reviews, :organization, index: true
    add_reference :workflows, :organization, index: true
  end
end
