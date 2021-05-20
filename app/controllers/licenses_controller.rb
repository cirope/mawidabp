# frozen_string_literal: true

class LicensesController < ApplicationController
  skip_before_action :redirect_to_license_blocked if ENABLE_PUBLIC_REGISTRATION
  before_action :set_license

  def show
  end

  def update
    @license.update(license_params) && @license.check_subscription
  end

  private

    def set_license
      @license = Current.group.license
    end

    def license_params
      params.require(:license).permit :subscription_id
    end
end
