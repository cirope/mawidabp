class AddSkipCommitmentSupportToFindingAnswers < ActiveRecord::Migration[6.0]
  def change
    change_table :finding_answers do |t|
      t.boolean :skip_commitment_support, null: false, default: false
    end
  end
end
