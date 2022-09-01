class AddLogoStyleToOrganizations < ActiveRecord::Migration[5.2]
  def change
    change_table :organizations do |t|
      t.string :logo_style, default: 'default', null: false
    end
  end
end
