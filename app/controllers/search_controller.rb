class SearchController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @subforums = Subforum.joins(:category).includes(:category).order("categories.position, categories.name, subforums.position, subforums.name")
    result = SearchService.new(query: @query, params: params).call
    @featured = result.featured
    @threads = result.threads
    @posts = result.posts
    @filters = result.filters
  end
end
