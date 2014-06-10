module ResourceClasses::Resources
  extend ActiveSupport::Concern

  included do
    has_many :resources, -> { order 'name ASC' }, dependent: :destroy

    accepts_nested_attributes_for :resources, allow_destroy: true
  end
end
