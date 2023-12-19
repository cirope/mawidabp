module PaginationHelper
  def paginate collection
    will_paginate collection,
      list_classes: %w(float-end pagination pagination-sm),
      renderer: WillPaginate::ActionView::BootstrapLinkRenderer
  end
end
