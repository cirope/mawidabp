class CreateEMails < ActiveRecord::Migration[4.2]
  def change
    create_table :e_mails do |t|
      t.text :to
      t.text :subject
      t.text :body
      t.text :attachments

      t.timestamps null: false
    end

    add_index :e_mails, :created_at
  end
end
