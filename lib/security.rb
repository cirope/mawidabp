module Security
  # That module is only needed if you need to store encrypted (symmetric) values
  ENCRYPTION = {
    iv:  (Base64.decode64(ENV['IV_ENCRYPTER'])  if ENV['IV_ENCRYPTER']),
    key: (Base64.decode64(ENV['KEY_ENCRYPTER']) if ENV['KEY_ENCRYPTER'])
  }

  def self.encrypt(value)
    cipher = new_cipher(:encrypt)
    Base64.encode64(cipher.update(value) + cipher.final)
  end

  def self.decrypt(value)
    decipher = new_cipher(:decrypt)
    decipher.update(Base64.decode64(value)) + decipher.final
  end

  def self.new_cipher(type)
    cipher = OpenSSL::Cipher::AES256.new(:CBC)
    cipher.send(type) # Needed for decrypt case
    cipher.iv = ENCRYPTION[:iv]
    cipher.key = ENCRYPTION[:key]
    cipher
  end
end
