if (type = ENV['ORGANIZATION_TYPE']).present?
  Figaro.application.path = Rails.root.join('config', "application.#{type}.yml")
  Figaro.load
end
