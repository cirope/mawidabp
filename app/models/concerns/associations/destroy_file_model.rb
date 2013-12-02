module Associations::DestroyFileModel
  extend ActiveSupport::Concern

  included do
    after_destroy :destroy_file_model
  end

  private
    def destroy_file_model
      if self.file_model
        self.class.where(file_model_id: self.file_model.id).each do |model|
          model.destroy!
        end

        self.file_model.destroy!
      end
    end
end
