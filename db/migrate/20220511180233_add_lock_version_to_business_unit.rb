# frozen_string_literal: true

class AddLockVersionToBusinessUnit < ActiveRecord::Migration[6.1]
  def change
    add_column :business_units, :lock_version, :integer, default: 0
  end
end
