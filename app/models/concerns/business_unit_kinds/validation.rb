module BusinessUnitKinds::Validation
  extend ActiveSupport::Concern

  included do
    validates :name, presence: true, length: { maximum: 255 }, uniqueness: true
  end
end
