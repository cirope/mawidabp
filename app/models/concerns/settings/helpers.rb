module Settings::Helpers
  extend ActiveSupport::Concern

  module ClassMethods
    def valid_setting? name
      value = find_by(name: name).value

      value != '0'
    end
  end
end
