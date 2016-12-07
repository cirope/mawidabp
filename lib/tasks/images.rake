namespace :images do
  desc 'Recreate all image model versions'
  task recreate: :environment do
    ImageModel.unscoped.find_each do |image_model|
      image_model.organization_id = image_model.imageable&.organization_id

      image_model.image.recreate_versions! if image_model.image?
    end
  end
end
