# frozen_string_literal: true

class CategoriesController < ApplicationController
  def index
    redirect_to root_path
  end

  def show
    @category = Category.find(params[:id])
    @subforums = @category.subforums.order(:position, :name)
  end
end
