module Auditable
  extend ActiveSupport::Concern

  included do
    has_paper_trail meta: {
      organization_id: ->(model) { Current.organization_id }
    }
  end
end
