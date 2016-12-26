jQuery(function ($) {
  $(document).on('shown.bs.collapse', '#ldap_config', function () {
    $('#ldap_config fieldset').prop('disabled', false)
    $('#organization_ldap_config_attributes_hostname').focus()
  })

  $(document).on('hidden.bs.collapse', '#ldap_config', function () {
    $('#ldap_config fieldset').prop('disabled', true)
  })
})
