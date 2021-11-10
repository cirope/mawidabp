module ActivityGroups::Activities
  extend ActiveSupport::Concern

  included do
    has_many :activities, -> { order :name }, dependent: :destroy, inverse_of: :activity_group

    accepts_nested_attributes_for :activities, allow_destroy: true, reject_if: :all_blank
  end
end
