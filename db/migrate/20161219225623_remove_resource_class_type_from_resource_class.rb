class RemoveResourceClassTypeFromResourceClass < ActiveRecord::Migration
  def change
    remove_human_resources

    remove_column :resource_classes, :resource_class_type
  end

  private

    def remove_human_resources
      ResourceClass.unscoped.where(resource_class_type: 0).destroy_all
    end
end
