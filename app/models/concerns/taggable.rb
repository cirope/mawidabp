module Taggable
  extend ActiveSupport::Concern

  included do
    has_many :taggings, as: :taggable, dependent: :destroy,
      after_add: :_tagging_added, after_remove: :_tagging_removed
    has_many :tags, through: :taggings

    accepts_nested_attributes_for :taggings, allow_destroy: true, reject_if: :all_blank
  end

  module ClassMethods
    def tagged_with *tags
      condition = if tags.all? { |t| t.respond_to? :id }
                    { id: tags.map(&:id) }
                  else
                    { name: tags }
                  end

      joins(:tags).where(tags: condition).distinct
    end

    def by_tags tags
      tagged_with *tags.strip.split(/\s*,\s*/)
    end
  end

  private

    def _tagging_added tagging
      tagging_added tagging if respond_to? :tagging_added
    end

    def _tagging_removed tagging
      tagging_removed tagging if respond_to? :tagging_removed
    end
end
