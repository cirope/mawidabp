module PaginationHelper
  def paginate collection
    will_paginate collection, class: 'pull-right small pagination-sm',
      renderer: BootstrapPagination::Rails
  end
end
