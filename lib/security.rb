module Security
  def self.encrypt(value)
    crypt.encrypt_and_sign(value)
  end

  def self.decrypt(value)
    crypt.decrypt_and_verify(value)
  end

  def self.crypt
    # Secret key with Encryptor defaults
    ActiveSupport::MessageEncryptor.new(
      Rails.application.secrets.secret_key_base[0..31]
    )
  end
end
