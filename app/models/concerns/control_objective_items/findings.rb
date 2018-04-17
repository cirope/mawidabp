module ControlObjectiveItems::Findings
  extend ActiveSupport::Concern

  included do
    has_many :weaknesses,   -> { where final: false }, dependent: :destroy
    has_many :oportunities, -> { where final: false }, dependent: :destroy

    has_many :final_weaknesses,   -> { where final: true },
      dependent: :destroy, class_name: 'Weakness'
    has_many :final_oportunities, -> { where final: true },
      dependent: :destroy, class_name: 'Oportunity'
  end
end
