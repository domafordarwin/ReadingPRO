# frozen_string_literal: true

module ApiPagination
  extend ActiveSupport::Concern

  private

  def paginate_collection(collection)
    page = params[:page].to_i.positive? ? params[:page].to_i : 1
    per_page = [params[:per_page].to_i.positive? ? params[:per_page].to_i : 25, 100].min

    paginated = collection.page(page).per(per_page)

    meta = {
      page: page,
      per_page: per_page,
      total: collection.count,
      total_pages: (collection.count.to_f / per_page).ceil
    }

    [paginated, meta]
  end
end
