module Findings::Taggable
  extend ActiveSupport::Concern

  include Taggable

  def tagging_added tagging
    if sync_taggings? && valid?
      exists = final_twin.taggings.where(tag_id: tagging.tag_id).any?

      final_twin.taggings.create! tag_id: tagging.tag_id unless exists
    end
  end

  def tagging_removed tagging
    if sync_taggings? && valid?
      final_twin.taggings.where(tag_id: tagging.tag_id).destroy_all
    end
  end

  private

    def sync_taggings?
      WEAKNESS_TAG_SYNC && final == false && final_twin
    end

    def final_twin
      children.take&.final && children.take
    end
end
