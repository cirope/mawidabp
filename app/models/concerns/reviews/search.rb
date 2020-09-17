module Reviews::Search
  extend ActiveSupport::Concern
  include Searchable

  included do
    COLUMNS_FOR_SEARCH = {
      period: {
        column: "LOWER(#{Period.quoted_table_name}.#{Period.qcn 'name'})"
      },
      identification: {
        column: "LOWER(#{quoted_table_name}.#{qcn 'identification'})"
      },
      business_unit: {
        column: "LOWER(#{BusinessUnit.quoted_table_name}.#{BusinessUnit.qcn 'name'})"
      },
      project: {
        column: "LOWER(#{::PlanItem.quoted_table_name}.#{::PlanItem.qcn 'project'})"
      },
      audit_team: {
        column: "LOWER(#{User.quoted_table_name}.#{User.qcn 'last_name'})"
      }
    }.with_indifferent_access

    if POSTGRESQL_ADAPTER
      COLUMNS_FOR_SEARCH.merge!(
        tags: {
          column: "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'})"
        }
      ).with_indifferent_access
    end
  end

  module ClassMethods
    def search query: nil, columns: [], default_conditions: {}
      with_tags = columns.delete 'tags'
      scoped    = query.present? && columns.empty? ? none : super

      if with_tags && POSTGRESQL_ADAPTER
        tags_query = split_terms_in_query query
        tags_scope = search_by_tags tags_query.flatten.uniq, tags_query.size
        scoped     = scoped.or tags_scope
      end

      scoped.allowed_by_business_units
    end

    def search_by_tags tags, min_tag_count
      having = "COUNT(DISTINCT #{Tag.quoted_table_name}.#{Tag.qcn 'id'}) >= ?"
      query  = tags.join ' OR '

      ids = where(
        *[prepare_search(raw_query: query, columns: ['tags'])].flatten
      ).
      having(having, min_tag_count).
      group(:id).
      pluck 'id'

      where id: ids
    end
  end
end
