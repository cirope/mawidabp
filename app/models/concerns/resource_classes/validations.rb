module ResourceClasses::Validations
  extend ActiveSupport::Concern
  include ResourceClasses::ResourceTypes

  included do
    validates :name, :resource_class_type, :organization, presence: true
    validates :name, length: { maximum: 255 },
      uniqueness: { case_sensitive: false, scope: :organization }
    validates :name, format: { with: /\A\w[\w\s]*\z/ }, allow_nil: true,
      allow_blank: true
    validates :resource_class_type, inclusion: { in: TYPES.values },
      allow_nil: true, allow_blank: true
  end
end
