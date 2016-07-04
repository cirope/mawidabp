module FiltersHelper
  def date_filter_operators
    options = %w(= < > <= >=).map { |o| [o, o] }

    options << [t('.between'), 'between']
  end
end
