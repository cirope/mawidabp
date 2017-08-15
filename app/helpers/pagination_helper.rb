module PaginationHelper
  def paginate collection
    will_paginate collection, class: 'pull-right small pagination-sm'
  end
end
