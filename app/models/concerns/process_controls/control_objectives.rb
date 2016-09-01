module ProcessControls::ControlObjectives
  extend ActiveSupport::Concern

  included do
    has_many :control_objectives, -> { order order: :asc }, dependent: :destroy

    accepts_nested_attributes_for :control_objectives, allow_destroy: true,
      reject_if: -> (attributes) { attributes['name'].blank? }
  end
end
