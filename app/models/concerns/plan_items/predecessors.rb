module PlanItems::Predecessors
  extend ActiveSupport::Concern

  included do
    serialize :predecessors, Array
  end

  def plain_predecessors
    predecessors&.to_sentence
  end

  def plain_predecessors= plain_predecessors
    self.predecessors = (plain_predecessors || '').split(/\D+/).map do |p|
      p.to_i if p.respond_to?(:to_i)
    end.compact.sort
  end
end
