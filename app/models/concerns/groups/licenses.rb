module Groups::Licenses
  extend ActiveSupport::Concern

  included do
    scope :licensed, -> { where licensed: true }

    attr_accessor :users_left_count
  end

  def auditors_limit
    licensed? ? license.auditors_limit : Rails.application.credentials.auditors_limit
  end

  def auditor_users_count
    users.can_act_as(:auditor).unscope(:order).distinct.select("#{User.table_name}.id").count
  end

  def can_create_auditor?
    self.users_left_count = auditors_limit - auditor_users_count

    users_left_count.positive?
  end
end
