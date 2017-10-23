module SearchableByTag
  extend ActiveSupport::Concern

  def build_tag_search_for scope
    if has_tag_query?
      query         = split_query_param
      having        = "COUNT(#{Tag.quoted_table_name}.#{Tag.qcn 'id'}) >= ?"
      min_tag_count = query.size
      ids = scope.
        where(*tags_conditions(query)).
        having(having, min_tag_count).
        group(:id).
        pluck 'id'

      scope.where id: ids
    else
      scope.none
    end
  end

  private

    def has_tag_query?
      params[:search] &&
        params[:search][:query].present? &&
        params[:search][:columns].present? &&
        params[:search][:columns].include?('tags')
    end

    def split_query_param
      raw_query = params[:search][:query].to_s.mb_chars.downcase.to_s
      and_query = raw_query.split(SEARCH_AND_REGEXP).reject &:blank?

      and_query.map { |query| query.split(SEARCH_OR_REGEXP).reject &:blank? }
    end

    def tags_conditions query
      column     = "LOWER(#{Tag.quoted_table_name}.#{Tag.qcn 'name'})"
      parameters = {}
      conditions = []

      query.each_with_index do |or_query, i|
        or_conditions = []

        or_query.each_with_index do |q, j|
          or_conditions << "#{column} LIKE :tag_name_#{i}_#{j}"
          parameters[:"tag_name_#{i}_#{j}"] = "%#{q}%"
        end

        conditions << or_conditions.join(' OR ')
      end

      # It is OR instead of AND, later whit COUNT we filter, not ideal but close
      [conditions.map { |c| "(#{c})" }.join(' OR '), parameters]
    end
end
