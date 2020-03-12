module SearchHelper
  def search_columns_for_model model
    search_params[:columns] || model::COLUMNS_FOR_SEARCH.keys
  end
end
