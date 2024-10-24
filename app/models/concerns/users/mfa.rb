module Users::Mfa
  extend ActiveSupport::Concern

  included do
    acts_as_google_authenticated lookup_token: :mfa_salt
  end

  def require_mfa?
    org_roles = organization_roles.where organization_id: Current.organization&.id

    org_roles.any? &:require_mfa
  end

  def mfa_config_done!
    update!(
      mfa_configured_at: Time.zone.now,
      mfa_salt:          SecureRandom.hex
    )
  end

  def mfa_qr
    content = "otpauth://totp/#{email}?secret=#{google_secret_value}"
    qrcode  = RQRCode::QRCode.new content

    qrcode.as_svg module_size: 5
  end
end
