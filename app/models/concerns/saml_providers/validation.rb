# frozen_string_literal: true

module SamlProviders::Validation
  extend ActiveSupport::Concern

  included do
    PROVIDERS = %w(azure)

    validates :provider, inclusion: { in: PROVIDERS }
    validates :idp_homepage, :idp_entity_id, :idp_sso_target_url,
              :sp_entity_id, :assertion_consumer_service_url, :name_identifier_format,
              :assertion_consumer_service_binding, :idp_cert, presence: true
    validates :idp_homepage, :idp_entity_id, :idp_sso_target_url,
              :sp_entity_id, :assertion_consumer_service_url, :name_identifier_format,
              :assertion_consumer_service_binding, length: { maximum: 255 }
    validate  :valid_default_role_for_users, if: -> { default_role_for_users.present? }
  end

  private

    def valid_default_role_for_users
      errors.add :default_role_for_users, :invalid if default_role_for_users.organization != organization
    end
end
