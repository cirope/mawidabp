# frozen_string_literal: true

module SamlProviders::Validations
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
  end
end
