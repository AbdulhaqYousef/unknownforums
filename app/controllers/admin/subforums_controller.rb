class Admin::SubforumsController < ApplicationController
  before_action :require_admin
  before_action :set_subforum, only: %i[edit update destroy]

  def index
    @subforums = Subforum.includes(:category).references(:category).order("categories.position, subforums.position")
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @subforums = @subforums.where("subforums.name ILIKE :query OR subforums.description ILIKE :query OR categories.name ILIKE :query", query: query)
    end
  end

  def new
    @subforum = Subforum.new
    @categories = Category.all
  end

  def create
    @subforum = Subforum.new(subforum_params)
    if @subforum.save
      redirect_to admin_subforums_path, notice: "Subforum created."
    else
      @categories = Category.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @categories = Category.all
  end

  def update
    if @subforum.update(subforum_params)
      redirect_to admin_subforums_path, notice: "Subforum updated."
    else
      @categories = Category.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @subforum.destroy
    redirect_to admin_subforums_path, notice: "Subforum deleted."
  end

  private

  def set_subforum
    @subforum = Subforum.find(params[:id])
  end

  def subforum_params
    params.require(:subforum).permit(:name, :description, :category_id, :position)
  end
end
