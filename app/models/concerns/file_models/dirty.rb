module FileModels::Dirty
  extend ActiveSupport::Concern

  def changed?
    file.cached?.present? || super
  end
end
