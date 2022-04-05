# frozen_string_literal: true

class AddRollingDeploymentsFieldsGalToControlObjectives < ActiveRecord::Migration[6.0]
  def change
    add_column :control_objectives, :audit_sector, :string
    add_column :control_objectives, :date_charge, :date

    create_table :control_objective_auditors do |t|
      t.belongs_to :user
      t.belongs_to :control_objective
    end
  end
end
