if (type = ENV['ORGANIZATION_TYPE']).present? &&
   File.exist?(path = Rails.root.join('config', "application.#{type}.yml"))

  Figaro.application.path = path
  Figaro.load
end
