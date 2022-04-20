module Findings::Extension
  extend ActiveSupport::Concern

  def not_extension?
    USE_SCOPE_CYCLE && extension ? false : true
  end

  def not_extension_was?
    USE_SCOPE_CYCLE && extension_was ? false : true
  end

  module ClassMethods
    def states_that_allow_extension
      [Finding::STATUS[:being_implemented], Finding::STATUS[:awaiting]]
    end
  end
end
