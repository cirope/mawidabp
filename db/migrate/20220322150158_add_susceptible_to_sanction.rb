# frozen_string_literal: true

class AddSusceptibleToSanction < ActiveRecord::Migration[6.0]
  def change
    add_column :findings, :compliance_susceptible_to_sanction, :boolean
  end
end
