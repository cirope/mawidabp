module Users::PasswordsHelper
  def confirmation_hash
    params[:confirmation_hash] || @auth_user.confirmation_hash
  end
end
