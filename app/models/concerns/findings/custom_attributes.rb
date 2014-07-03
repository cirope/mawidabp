module Findings::CustomAttributes
  extend ActiveSupport::Concern

  included do
    attr_accessor :nested_user,
      :finding_prefix,
      :avoid_changes_notification,
      :users_for_notification,
      :user_who_make_it,
      :nested_finding_relation,
      :force_modification,
      :undoing_reiteration
  end
end
