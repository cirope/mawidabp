module Organizations::Parameters
  extend ActiveSupport::Concern

  module ClassMethods
    def all_parameters name
      all.map do |organization|
        {
          organization: organization,
          parameter:    organization.settings.find_by(name: name).try(:value)
        }
      end
    end
  end
end
