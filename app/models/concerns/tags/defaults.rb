module Tags::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.group_id        = Current.group&.id
      self.organization_id = Current.organization&.id

      inherit_parent_attributes
    end

    def inherit_parent_attributes
      if parent
        self.kind     = parent.kind
        self.icon     = parent.icon
        self.style    = parent.style
        self.shared   = parent.shared
        self.obsolete = parent.obsolete
      end
    end
end
