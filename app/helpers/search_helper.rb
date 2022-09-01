module SearchHelper
  def search_columns_for_model model, exclude = []
    (search_params[:columns] || model::COLUMNS_FOR_SEARCH.keys) - exclude
  end
end
