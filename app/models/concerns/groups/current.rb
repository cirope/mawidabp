module Groups::Current
  extend ActiveSupport::Concern

  included do
    before_save :change_current_group
    after_save :restore_current_group
  end

  private

    def change_current_group
      @_current_group = ::Current.group
      ::Current.group = self if id
    end

    def restore_current_group
      ::Current.group = @_current_group
    end
end
