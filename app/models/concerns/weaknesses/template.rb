module Weaknesses::Template
  extend ActiveSupport::Concern

  included do
    attr_reader :weakness_template_from_control_objective

    belongs_to :weakness_template, optional: true
  end
end
