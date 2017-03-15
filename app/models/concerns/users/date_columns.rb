module Users::DateColumns
  extend ActiveSupport::Concern

  included do
    attribute :password_changed, :date
  end
end
