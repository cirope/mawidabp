module ResourceClasses::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :organization, presence: true
    validates :name, length: { maximum: 255 }, pdf_encoding: true,
      uniqueness: { case_sensitive: false, scope: :organization }
  end
end
