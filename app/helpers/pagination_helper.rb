module PaginationHelper
  def paginate collection
    will_paginate collection, class: 'pull-right small', renderer: BootstrapPagination::Rails
  end
end
