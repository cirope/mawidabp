module ControlObjectives::Control
  extend ActiveSupport::Concern

  included do
    has_one :control, -> {
      order "#{Control.quoted_table_name}.#{Control.qcn('order')} ASC"
    }, as: :controllable, dependent: :destroy

    accepts_nested_attributes_for :control, allow_destroy: true
  end
end
