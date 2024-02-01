class AddStatusToWorkPapers < ActiveRecord::Migration[6.1]
  def change
    add_column :work_papers, :status, :string
  end
end
