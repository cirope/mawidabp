# frozen_string_literal: true

module Subsidiaries::Scopes
  extend ActiveSupport::Concern

  included do
    scope :list, -> {
      where(organization_id: Current.organization&.id).order name: :asc
    }
  end
end
