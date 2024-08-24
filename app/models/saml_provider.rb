# frozen_string_literal: true

class SamlProvider < ApplicationRecord
  include Trimmer
  include SamlProviders::Validation

  belongs_to :default_role_for_users, class_name: 'Role', optional: true
  belongs_to :organization

  trimmed_fields :idp_homepage, :idp_entity_id, :idp_sso_target_url,
                 :sp_entity_id, :assertion_consumer_service_url, :name_identifier_format,
                 :assertion_consumer_service_binding, :idp_cert

  def to_s
    provider
  end
end
