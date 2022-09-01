# frozen_string_literal: true

class Licenses::CheckController < ApplicationController
  skip_before_action :redirect_to_license_blocked if ENABLE_PUBLIC_REGISTRATION
  before_action :set_license

  def create
    @license.check_subscription
  end

  private

    def set_license
      @license = Current.group.license
    end
end
