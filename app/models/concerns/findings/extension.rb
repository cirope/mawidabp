module Findings::Extension
  extend ActiveSupport::Concern

  def not_extension?
    USE_SCOPE_CYCLE && extension ? false : true
  end

  def not_extension_was?
    USE_SCOPE_CYCLE && extension_was ? false : true
  end
end
