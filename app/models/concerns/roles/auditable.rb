module Roles::Auditable
  extend ActiveSupport::Concern

  included do
    has_paper_trail meta: {
      organization_id: ->(model) { Current.organization&.id },
      important: true
    }
  end
end
