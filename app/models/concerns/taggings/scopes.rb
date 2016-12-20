module Taggings::Scopes
  extend ActiveSupport::Concern

  included do
    scope :for_document, -> {
      joins(:tag).where tags: { kind: 'document' }
    }
    scope :with_documents, -> {
      for_document.joins(:document).merge Document.list
    }
    scope :grouped_with_document_count, -> {
      with_documents.group(
        :tag_id,
        "#{Tag.quoted_table_name}.#{Tag.qcn 'name'}",
        "#{Tag.quoted_table_name}.#{Tag.qcn 'icon'}",
        "#{Tag.quoted_table_name}.#{Tag.qcn 'style'}"
      ).count
    }
  end
end
