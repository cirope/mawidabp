class CreateLicenses < ActiveRecord::Migration[6.0]
  def change
    create_table :licenses do |t|
      t.references :group, null: false, foreign_key: FOREIGN_KEY_OPTIONS.dup
      t.string :status, null: false, default: License.statuses[:trial]
      t.integer :auditors_limit, null: false
      t.string :subscription_id, index: true
      t.datetime :subscribed_until, index: true

      t.timestamps null: false
    end
  end
end
