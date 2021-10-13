module Findings::Extension
  extend ActiveSupport::Concern

  def not_extension?
    USE_SCOPE_CYCLE && extension ? false : true
  end
end
