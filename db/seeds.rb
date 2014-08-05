def self.check_errors(record)
  if record.errors.size > 0
    puts "Error in #{record.class}:"
    record.errors.each { |error| p error }
    return false
  else
    puts "#{record.class} ... [OK]"
    return true
  end
end

User.paper_trail_off

user = User.new(
  :name => 'Administrator',
  :last_name => 'Administrator',
  :language => 'es',
  :email => SUPPORT_EMAIL,
  :enable => true,
  :password_changed => nil,
  :user => 'admin',
  :password => 'admin123'
)

user.group_admin = true
user.roles.each { |r| r.inject_auth_privileges Hash.new(Hash.new(true)) }
user.encrypt_password
user.save

check_errors user

User.paper_trail_on
