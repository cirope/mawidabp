module NewsModule::Defaults
  extend ActiveSupport::Concern

  included do
    after_initialize :set_defaults, if: :new_record?
  end

  private

    def set_defaults
      self.published_at  ||= Time.zone.now
      self.group_id        = Current.group_id
      self.organization_id = Current.organization_id
    end
end
