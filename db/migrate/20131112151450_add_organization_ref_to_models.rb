class AddOrganizationRefToModels < ActiveRecord::Migration
  def change
    add_reference :reviews, :organization, index: true
    add_reference :conclusion_reviews, :organization, index: true
  end
end
