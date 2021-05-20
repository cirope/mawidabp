class CreateWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :webhooks do |t|
      t.string :gateway, null: false, index: true
      t.string :status, null: false, index: true
      t.string :kind, null: false
      t.string :reference_id, null: false

      t.timestamps null: false
    end
  end
end
