module Findings::Extension
  extend ActiveSupport::Concern

  module ClassMethods
    def states_that_allow_extension
      [Finding::STATUS[:being_implemented], Finding::STATUS[:awaiting]]
    end
  end
end
