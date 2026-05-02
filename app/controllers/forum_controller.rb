class ForumController < ApplicationController
  def index
    @categories = Category.includes(subforums: :category).all
  end
end
