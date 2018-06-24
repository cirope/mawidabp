module Organizations::Current
  extend ActiveSupport::Concern

  included do
    before_save :change_current_organization_id
    after_save :restore_current_organization_id
  end

  private

    def change_current_organization_id
      @_current_organization_id = Current.organization_id
      Current.organization_id = id if id
    end

    def restore_current_organization_id
      Current.organization_id = @_current_organization_id
    end
end
