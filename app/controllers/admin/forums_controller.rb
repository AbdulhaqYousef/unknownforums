class Admin::ForumsController < ApplicationController
  before_action :require_admin

  def index
    @categories = Category.includes(:subforums).order(:position, :name)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @categories = @categories.where("categories.name ILIKE :query OR categories.description ILIKE :query OR EXISTS (SELECT 1 FROM subforums WHERE subforums.category_id = categories.id AND (subforums.name ILIKE :query OR subforums.description ILIKE :query))", query: query)
    end
    @new_category = Category.new
    @new_subforum = Subforum.new
  end
end
