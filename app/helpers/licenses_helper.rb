# frozen_string_literal: true

module LicensesHelper
  def license_status status
    t "licenses.statuses.#{status}"
  end

  def paypal_script_source
    paypal_params = {
      currency:          'USD',
      vault:             'true',
      'client-id':       Rails.application.credentials.paypal[:client_id],
      'disable-funding': 'credit,card'
    }

    "https://www.paypal.com/sdk/js?#{paypal_params.to_param}"
  end
end
