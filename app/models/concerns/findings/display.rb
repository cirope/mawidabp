module Findings::Display
  extend ActiveSupport::Concern

  def to_s
    "#{review_code} - #{title} - #{control_objective_item.try(:review)}"
  end

  alias_method :label, :to_s

  def informal
    text = "<strong>#{Finding.human_attribute_name 'title'}</strong>: "
    text << title.to_s
    text << "<br /><strong>#{Finding.human_attribute_name 'review_code'}</strong>: "
    text << review_code
    text << "<br /><strong>#{Review.model_name.human}</strong>: "
    text << control_objective_item.review.to_s
    text << "<br /><strong>#{Finding.human_attribute_name 'state'}</strong>: "
    text << state_text
    text << "<br /><strong>#{ControlObjectiveItem.human_attribute_name 'control_objective_text'}</strong>: "
    text << control_objective_item.to_s
  end
end
