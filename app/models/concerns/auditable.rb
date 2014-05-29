module Auditable
  extend ActiveSupport::Concern

  included do
    has_paper_trail meta: {
      organization_id: ->(model) { Organization.current_id }
    }
  end
end
