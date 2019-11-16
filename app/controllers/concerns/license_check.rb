# frozen_string_literal: true

module LicenseCheck
  extend ActiveSupport::Concern

  included do
    before_action :redirect_to_license_blocked, if: :blocked_group?
  end

  private

    def redirect_to_license_blocked
      if request.format.html?
        redirect_to license_blocked_url, status: 307
      else
        render body: nil, status: 402
      end
    end

    def blocked_group?
      Current.group&.licensed? && Current.group.license&.blocked?
    end
end
