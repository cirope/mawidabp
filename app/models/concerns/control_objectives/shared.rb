module ControlObjectives::Shared
  extend ActiveSupport::Concern

  included do
    before_save :mark_tags_as_shared
  end

  def mark_as_shared
    mark_tags_as_shared
  end

  private

    def mark_tags_as_shared
      if best_practice&.shared
        taggings.each do |tagging|
          tagging.tag.update! shared: true unless tagging.tag.shared
        end
      end
    end
end
