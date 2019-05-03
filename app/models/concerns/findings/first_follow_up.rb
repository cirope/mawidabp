module Findings::FirstFollowUp
  extend ActiveSupport::Concern

  included do
    before_save :store_first_follow_up_date
  end

  def store_first_follow_up_date
    self.first_follow_up_date ||= first_follow_up_date_value
  end

  def first_follow_up_date_on_versions
    version = versions.detect do |v|
      v.reify&.follow_up_date
    end

    version&.reify&.follow_up_date || follow_up_date
  end

  private

    def first_follow_up_date_value
      is_first_follow_up_date = follow_up_date_changed?   &&
                                follow_up_date.present?   &&
                                follow_up_date_was.blank?

      follow_up_date if is_first_follow_up_date
    end
end
