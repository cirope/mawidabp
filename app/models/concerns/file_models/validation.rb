module FileModels::Validation
  extend ActiveSupport::Concern

  included do
    validates :file_file_name, :file_content_type, presence: true,
      length: { maximum: 255 }
    validates_each :file do |record, attr, value|
      if record.identifier && File.extname(record.identifier).blank?
        record.errors.add attr, :without_extension
      end
    end
  end
end
