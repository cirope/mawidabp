# frozen_string_literal: true

class Licenses::AuthorizationsController < ApplicationController
  skip_before_action :redirect_to_license_blocked if ENABLE_PUBLIC_REGISTRATION
  before_action :set_license, :set_title

  def new
  end

  def create
    auditors_limit = authorization_params[:auditors_limit].to_i

    @license.change_auditors_limit auditors_limit

    respond_with @license, location: license_url
  end

  private

    def set_license
      @license = Current.group.license
    end

    def authorization_params
      params.require(:license).permit(:auditors_limit)
    end
end
