module Findings::FollowUpLastChanged
  extend ActiveSupport::Concern

  included do
    before_save :store_follow_up_date_last_changed
  end

  def store_follow_up_date_last_changed
    if follow_up_date_was != follow_up_date
      self.follow_up_date_last_changed = Time.zone.today
    end
  end

  def follow_up_date_last_changed_on_versions
    act = self

    versions.map(&:reify).reject(&:blank?).reverse_each do |reify|
      if act.follow_up_date != reify.follow_up_date
        return I18n.l(act.updated_at, format: :minimal)
      end

      act = reify
    end

    act.follow_up_date.present? ? I18n.l(act.updated_at, format: :minimal) : nil
  end
end
