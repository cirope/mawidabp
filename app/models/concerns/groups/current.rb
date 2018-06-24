module Groups::Current
  extend ActiveSupport::Concern

  included do
    before_save :change_current_group_id
    after_save :restore_current_group_id
  end

  private

    def change_current_group_id
      @_current_group_id = Current.group_id
      Current.group_id = id if id
    end

    def restore_current_group_id
      Current.group_id = @_current_group_id
    end
end
