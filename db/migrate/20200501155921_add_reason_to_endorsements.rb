class AddReasonToEndorsements < ActiveRecord::Migration[6.0]
  def change
    change_table :endorsements do |t|
      t.string :reason
    end
  end
end
