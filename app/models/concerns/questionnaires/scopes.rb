module Questionnaires::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> { where organization_id: Organization.current_id }
    scope :pollable, -> {
      where.not(pollable_type: nil).where.not(pollable_type: '')
    }
    scope :not_pollable, -> {
      where(pollable_type: nil).or where(pollable_type: '')
    }
  end

  module ClassMethods
    def by_pollable_type type
      where pollable_type: type
    end

    def by_organization organization_id, id
      unscoped.where id: id, organization_id: organization_id
    end
  end
end
