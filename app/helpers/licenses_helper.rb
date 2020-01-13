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

  def license_auditors_limit_input form
    prices = LICENSE_PLANS.map do |k, v|
      [k, number_to_currency(v[:price].to_f)]
    end.to_h

    form.input :auditors_limit,
      as: :select,
      collection: LICENSE_PLANS.keys,
      include_blank: false,
      input_html: {
        data: {
          plans_with_prices: prices
        }
      }
  end
end
