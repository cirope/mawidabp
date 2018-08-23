module Organizations::Current
  extend ActiveSupport::Concern

  included do
    before_save :change_current_organization
    after_save :restore_current_organization
  end

  private

    def change_current_organization
      @_current_organization = ::Current.organization
      ::Current.organization = self if id
    end

    def restore_current_organization
      ::Current.organization = @_current_organization
    end
end
