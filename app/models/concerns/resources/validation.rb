module Resources::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true, pdf_encoding: true
    validates :name, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :name, uniqueness: { case_sensitive: false, scope: :resource_class }
    validates :description, pdf_encoding: true
  end
end
