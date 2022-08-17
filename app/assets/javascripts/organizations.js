jQuery(function ($) {
  $(document).on('shown.bs.collapse', '#ldap_config', function () {
    $('#ldap_config fieldset').prop('disabled', false)
    $('#organization_ldap_config_attributes_hostname').focus()
  })

  $(document).on('hidden.bs.collapse', '#ldap_config', function () {
    $('#ldap_config fieldset').prop('disabled', true)
  })

  $(document).on('shown.bs.collapse', '#saml_provider', function () {
    $('#saml_provider fieldset').prop('disabled', false)
    $('#organization_saml_provider_attributes_provider').focus()
  })

  $(document).on('hidden.bs.collapse', '#saml_provider', function () {
    $('#saml_provider fieldset').prop('disabled', true)
  })
})
