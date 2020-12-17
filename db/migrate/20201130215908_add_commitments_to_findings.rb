class AddCommitmentsToFindings < ActiveRecord::Migration[6.0]
  def change
    change_table :findings do |t|
      if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
        t.jsonb :commitments
      else
        t.text :commitments
      end
    end
  end
end
