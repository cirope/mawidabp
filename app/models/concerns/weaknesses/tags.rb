module Weaknesses::Tags
  extend ActiveSupport::Concern

  # Override custom tag_ids so it can be used "on the fly" with tagging
  # attributes
  def tag_ids
    taggings.reject(&:marked_for_destruction?).map &:tag_id
  end
end
