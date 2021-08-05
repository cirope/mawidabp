module Annexes::Validation
  extend ActiveSupport::Concern

  included do
    # validates :title, presence: true, length: { maximum: 255 }
    # validates :description, presence: true
  end
end
