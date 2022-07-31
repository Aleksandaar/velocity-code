class AuthorFinder

  class InvalidParametersError < StandardError; end

  attr_accessor :params, :query

  def initialize(params = {})
    @params = params
    @query = Writer
  end

  def call
    build_query
    execute_query
  end

  private

  def build_query
    add_starts_with_letter if params[:first_letter].present?
    add_search_phrase if params[:search_text].present? && params[:search_text] != ''
    include_deals_count if params[:include_deals_count]
    include_followers_count if params[:include_followers_count]
    filter_by_category if params[:category_id].present? && params[:category_id] != 'all'
    sort if params[:sort]
    filter_by_deal_id if params[:deal_id]
    filter_by_activated if params[:activated_only]
  end

  def execute_query
    @query
  end

  def add_search_phrase
    name_search = []
    name_params = []
    params[:search_text].split.each do |phrase|
      name_search << "(lower(writers.first_name) LIKE ? OR lower(writers.last_name) LIKE ?)"
      name_params << "%#{phrase.downcase}%"
      name_params << "%#{phrase.downcase}%"
    end

    @query = @query.where(name_search.join(' OR '), *name_params)
  end

  def add_starts_with_letter
    @query = @query.where("lower(writers.last_name) LIKE ? AND writers.activated = true", "#{params[:first_letter].downcase}%")
  end

  def filter_by_category
    @query = @query.joins("LEFT JOIN LATERAL (SELECT writers.id as writer_id, books_categories.category_id as category_id
                            FROM writers INNER JOIN book_writers ON book_writers.writer_id = writers.id
                            INNER JOIN books ON books.id = book_writers.book_id
                              JOIN books_categories on books_categories.book_id = books.id
                            GROUP BY (writers.id, books_categories.category_id)) category_info on category_info.writer_id = writers.id")
                    .where('category_info.category_id = ?', params[:category_id])
  end


  def filter_by_deal_id
    @query = @query.joins("LEFT JOIN LATERAL (SELECT writers.id as writer_id, books_deals.deal_id as deals_id
                            FROM writers INNER JOIN book_writers ON book_writers.writer_id = writers.id
                            INNER JOIN books ON books.id = book_writers.book_id
                              JOIN books_deals on books_deals.itemable_id = books.id
                                JOIN deals on deals.id = books_deals.deal_id
                            WHERE books_deals.itemable_type = 'Book'
                            GROUP BY (writers.id, books_deals.deal_id) ) deal_info on deal_info.writer_id = writers.id")
                   .where('deal_info.deals_id = ?', params[:deal_id])
  end

  def include_deals_count
    @query = @query.joins("LEFT JOIN LATERAL (SELECT book_writers.writer_id as writer_id, COUNT(DISTINCT deals.id) AS deals_count
                            FROM deals
                            INNER JOIN books_deals ON books_deals.deal_id = deals.id and books_deals.itemable_type = 'Book'
                              INNER JOIN books ON books.id = books_deals.itemable_id
                                INNER JOIN book_writers ON book_writers.book_id = books.id
                            WHERE book_writers.writer_id = writers.id
                            GROUP BY (book_writers.writer_id)) deals_info on deals_info.writer_id = writers.id")
                   .select("writers.*, deals_info.deals_count AS deals_count")
  end

  def include_followers_count
    @query = @query.joins("LEFT JOIN LATERAL (SELECT writers.id as writer_id, COUNT(followers.id) AS followers_count
                            FROM writers
                            INNER JOIN followers on followers.followed_id = writers.id
                            GROUP BY (writers.id)) followers_info on followers_info.writer_id = writers.id")
                   .select("writers.*, followers_info.followers_count AS followers_count")
  end

  def filter_by_activated
    @query = @query.where('writers.activated = true')
  end

  def sort
    sort = params[:sort].downcase.parameterize

    case sort
    when 'deals_count'
      include_deals_count
      @query = @query.order('deals_info.deals_count DESC NULLS LAST')
    when 'followers_count'
      include_followers_count
      @query = @query.order('followers_info.followers_count DESC NULLS LAST')
    when 'az'
      @query = @query.order([:first_name, :last_name])
    end
  end
end
