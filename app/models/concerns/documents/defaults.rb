module Documents::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.group_id        = Group.current_id
      self.organization_id = Organization.current_id
      self.shared          = !!shared
    end
end
