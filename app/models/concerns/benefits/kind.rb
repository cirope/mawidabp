module Benefits::Kind
  extend ActiveSupport::Concern

  def benefit?
    kind.start_with? 'benefit'
  end

  def damage?
    !benefit?
  end
end
