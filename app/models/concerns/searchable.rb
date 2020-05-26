module Searchable
  extend ActiveSupport::Concern

  module ClassMethods
    def extract_operator search_term
      operator = SEARCH_ALLOWED_OPERATORS.detect do |op_regex, _|
        search_term =~ op_regex
      end

      operator ? [search_term.sub(operator.first, ''), operator.last] : search_term
    end

    def allow_search_operator? operator, column
      [get_column_operator(column)].flatten.include? operator
    end

    def prepare_search_conditions *conditions
      (conditions.reject(&:blank?) || []).map { |c| "(#{sanitize(c)})" }.join ' AND '
    end

    def get_column_name column
      get_search_column(column)[:column]
    end

    def get_column_operator column
      get_search_column(column)[:operator] || 'LIKE'
    end

    def get_column_mask column
      get_search_column(column)[:mask] || '%%%s%%'
    end

    def get_column_conversion_method column
      get_search_column(column)[:conversion_method] || :to_s
    end

    def get_column_regexp column
      get_search_column(column)[:regexp] || /.*/
    end

    def get_search_column column
      self::COLUMNS_FOR_SEARCH[column] || {}
    end

    def date_column_options_for column
      {
        column:            column,
        operator:          SEARCH_ALLOWED_OPERATORS.values,
        mask:              '%s',
        conversion_method: ->(value) { Timeliness.parse(value, :date).to_s :db },
        regexp:            SEARCH_DATE_REGEXP
      }
    end

    def split_terms_in_query raw_query
      raw_query = raw_query.to_s.mb_chars.downcase.to_s
      and_query = raw_query.split(SEARCH_AND_REGEXP).reject &:blank?

      and_query.map { |q| q.split(SEARCH_OR_REGEXP).reject &:blank? }
    end

    def prepare_search raw_query: nil, columns: [], default_conditions: {}
      return default_conditions if columns.empty?

      query = split_terms_in_query raw_query

      search_string = []
      filters       = { boolean_false: false }

      query.each_with_index do |or_queries, i|
        or_search_string = []

        or_queries.each_with_index do |or_query, j|
          columns.each do |column|
            clean_or_query, operator = *extract_operator(or_query)

            if (
                clean_or_query =~ get_column_regexp(column) &&
                (!operator || allow_search_operator?(operator, column))
            )
              index             = i * 1000 + j
              mask              = get_column_mask column
              conversion_method = get_column_conversion_method column
              filter            = "#{get_column_name column } "
              operator          ||= if get_column_operator(column).kind_of?(Array)
                                      '='
                                    else
                                      get_column_operator column
                                    end

              or_search_string << "#{filter} #{operator} :#{column}_filter_#{index}"

              casted_value = if conversion_method.respond_to? :call
                               conversion_method.call clean_or_query.strip
                             else
                               clean_or_query.strip.send(conversion_method) rescue nil
                             end

              filters[:"#{column}_filter_#{index}"] = mask ? mask % casted_value : casted_value
            end
          end
        end

        search_string << "(#{or_search_string.join(' OR ')})" if or_search_string.present?
      end

      if search_string.empty?
        default_conditions
      else
        [
          prepare_search_conditions(default_conditions, search_string.join(' AND ')),
          filters
        ]
      end
    end

    def search query: nil, columns: [], default_conditions: {}
      if query.present? && columns.any?
        where(
          *[prepare_search(
            raw_query:          query,
            columns:            columns,
            default_conditions: default_conditions || {}
          )].flatten
        )
      elsif default_conditions.present?
        where default_conditions
      else
        all
      end
    end
  end
end
