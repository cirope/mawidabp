# frozen_string_literal: true

module ChunkIterator
  module_function

  ITERATOR_CHUNK_SIZE        = ENV['ITERATOR_CHUNK_SIZE'].try(:to_i) || 200
  ITERATOR_PAGES_UNTIL_FLUSH = ENV['ITERATOR_PAGES_UNTIL_FLUSH'].try(:to_i) || 4

  def iterate scope, per_page: ITERATOR_CHUNK_SIZE, pages_for_flush: ITERATOR_PAGES_UNTIL_FLUSH
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

