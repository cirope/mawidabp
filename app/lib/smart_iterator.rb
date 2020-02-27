# frozen_string_literal: true

module SmartIterator
  module_function

  DEFAULT_PER_PAGE        = ENV['ITERATOR_PER_PAGE'].try(:to_i) || 200
  DEFAULT_PAGES_FOR_FLUSH = ENV['ITERATOR_PAGES_FOR_FLUSH'].try(:to_i) || 4

  def iterate scope, per_page: DEFAULT_PER_PAGE, pages_for_flush: DEFAULT_PAGES_FOR_FLUSH
    page = 1

    while page
      Rails.logger.debug "#{Time.zone.now} iteration page: #{page}"
      cursor = scope.page(page).per_page per_page

      yield cursor

      if (page % pages_for_flush).zero?
        # Entire flush of AR
        ActiveRecord::Base.clear_active_connections!
        ActiveRecord::Base.connection_pool.flush!

        GC.start
      end

      page = cursor.next_page
    end
  end
end

