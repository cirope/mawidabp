module Organizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { order 'name ASC' }
  end

  module ClassMethods
    def list_for_group group
      where group_id: group.id
    end
  end
end
