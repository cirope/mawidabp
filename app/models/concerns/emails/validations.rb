module Emails::Validations
  extend ActiveSupport::Concern

  included do
    validates :to, :subject, presence: true
  end
end
