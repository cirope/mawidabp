module Organizations::SamlProvider
  extend ActiveSupport::Concern

  included do
    has_one :saml_provider, dependent: :destroy

    accepts_nested_attributes_for :saml_provider, allow_destroy: true
  end
end
