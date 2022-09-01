module PaginationHelper
  def paginate collection
    will_paginate collection,
      class:    'float-right pagination-sm',
      renderer: WillPaginate::ActionView::Bootstrap4LinkRenderer
  end
end
