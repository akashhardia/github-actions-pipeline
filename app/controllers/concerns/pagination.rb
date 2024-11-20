# frozen_string_literal: true

# paginationのモジュール
module Pagination
  extend ActiveSupport::Concern

  def resources_with_pagination(resources)
    {
      current: resources.current_page,
      previous: resources.prev_page,
      next: resources.next_page,
      limitValue: resources.limit_value,
      pages: resources.total_pages,
      count: resources.total_count,
      pageCount: resources.count
    }
  end
end
