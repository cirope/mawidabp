smtp_address  = Figaro.env.SMTP_ADDRESS
smtp_port     = Figaro.env.SMTP_PORT
smtp_domain   = Figaro.env.SMTP_DOMAIN
smtp_username = Figaro.env.SMTP_USER_NAME
smtp_password = Figaro.env.SMTP_PASSWORD

from_address = 'soporte@mawidabp.com'
to_address   = 'sergio@hullop.com'
subject      = 'Test Envio de Correo'
body         = 'Correo Enviado.'

# Crear el mensaje
mail = Mail.new do
  from from_address
  to to_address
  subject subject
  body body
end

# Enviar el correo
mail.delivery_method(:smtp, address: smtp_address, port: smtp_port, domain: smtp_domain, user_name: smtp_username, password: smtp_password)
mail.deliver!
