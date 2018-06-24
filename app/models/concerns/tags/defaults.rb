module Tags::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.group_id        = Current.group_id
      self.organization_id = Current.organization_id
    end
end
