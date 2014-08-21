module Organizations::Scopes
  extend ActiveSupport::Concern

  included do
    scope :ordered, -> { order 'name ASC' }
  end

  module ClassMethods
    def with_group group
      where group_id: group.id
    end

    def by_subdomain subdomain
      where("LOWER(prefix) = ?", subdomain.to_s.downcase).take
    end
  end
end
