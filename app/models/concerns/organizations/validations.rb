module Organizations::Validations
  extend ActiveSupport::Concern

  included do
    validates :prefix, format: { with: /\A[A-Za-z][A-Za-z0-9\-]+\z/ },
      allow_nil: true, allow_blank: true
    validates :name, :prefix, :kind, presence: true
    validates :name, :prefix, length: { maximum: 255 }, allow_nil: true,
      allow_blank: true
    validates :prefix, uniqueness: { case_sensitive: false }
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :prefix, exclusion: { in: APP_ADMIN_PREFIXES }
    validates :kind, inclusion: { in: ORGANIZATION_KINDS }, allow_nil: true,
      allow_blank: true
  end
end
