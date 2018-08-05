I18n.config.enforce_available_locales = true

old_handler = I18n.config.exception_handler
I18n.config.exception_handler = lambda do |exception, locale, key, options|
  scope = (options[:scope] || []).join('.')
  full_key = [locale, scope, key].join('.')
  begin
    ::File.open('missing', 'ab') { |f| f.puts "#{full_key.inspect} #{options.inspect rescue ''}" }
  rescue => e
    byebug
  end

  old_handler.call(exception, locale, key, options)
end
