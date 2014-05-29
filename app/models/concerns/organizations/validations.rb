module Organizations::Validations
  extend ActiveSupport::Concern

  included do
    validates :name, :prefix, presence: true, length: { maximum: 255 }
    validates :name, uniqueness: { case_sensitive: false, scope: :group_id }
    validates :kind, presence: true, inclusion: { in: ORGANIZATION_KINDS }
    validates :prefix,
      format: { with: /\A[A-Za-z][A-Za-z0-9\-]+\z/ },
      uniqueness: { case_sensitive: false },
      exclusion: { in: APP_ADMIN_PREFIXES }
  end
end
