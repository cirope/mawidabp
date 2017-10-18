module Groups::Current
  extend ActiveSupport::Concern

  included do
    before_save :change_current_group_id
    after_save :restore_current_group_id
  end

  module ClassMethods
    def current_id
      RequestStore.store[:current_group_id]
    end

    def current_id= group_id
      RequestStore.store[:current_group_id] = group_id
    end

    def corporate_ids
      RequestStore.store[:corporate_ids]
    end

    def corporate_ids= corporate_ids
      RequestStore.store[:corporate_ids] = corporate_ids
    end
  end

  private

    def change_current_group_id
      @_current_group_id = Group.current_id
      Group.current_id = id if id
    end

    def restore_current_group_id
      Group.current_id = @_current_group_id
    end
end
