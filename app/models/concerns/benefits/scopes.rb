module Benefits::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list,       -> { where organization_id: Organization.current_id }
    scope :tangible,   -> { where kind: 'tangible' }
    scope :intangible, -> { where kind: 'intangible' }
  end
end
