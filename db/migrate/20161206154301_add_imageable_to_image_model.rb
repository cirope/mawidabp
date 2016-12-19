class AddImageableToImageModel < ActiveRecord::Migration
  def change
    add_reference :image_models, :imageable, polymorphic: true, index: true

    put_imageable_attributes
    remove_blank_imageables

    change_column_null :image_models, :imageable_type, false
    change_column_null :image_models, :imageable_id, false
  end

  def put_imageable_attributes
    ImageModel.reset_column_information

    Organization.unscoped.find_each do |organization|
      image_model = ImageModel.find organization.image_model_id if organization.image_model_id

      image_model&.update_columns imageable_type: 'Organization', imageable_id: organization.id
    end
  end

  def remove_blank_imageables
    ImageModel.unscoped.where(imageable_type: nil).destroy_all
  end
end
