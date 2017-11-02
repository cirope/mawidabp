module Findings::Auditable
  extend ActiveSupport::Concern

  included do
    IGNORED_ATTRIBUTES = if SHOW_WEAKNESS_EXTRA_ATTRIBUTES
                           []
                         else
                           [:impact, :internal_control_components]
                         end

    has_paper_trail ignore: IGNORED_ATTRIBUTES, meta: {
      organization_id: ->(model) { Organization.current_id }
    }
  end
end
