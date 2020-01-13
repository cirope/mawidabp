class Licenses::BlockedController < ApplicationController
  skip_before_action :redirect_to_license_blocked if ENABLE_PUBLIC_REGISTRATION

  def show
  end
end
