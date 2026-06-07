class Admin::CategoriesController < ApplicationController
  include AdminFileTypeParams
  include AdminUploadLimitParams

  before_action :require_admin
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = Category.includes(:subforums).order(:position, :name)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @categories = @categories.where("categories.name ILIKE :query OR categories.description ILIKE :query", query: query)
    end
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)
    return render(:new, status: :unprocessable_entity) unless apply_record_file_type_settings(@category)
    return render(:new, status: :unprocessable_entity) unless apply_record_upload_limit_settings(@category)

    if @category.save
      redirect_to admin_categories_path, notice: "Category created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    @category.assign_attributes(category_params)
    return render(:edit, status: :unprocessable_entity) unless apply_record_file_type_settings(@category)
    return render(:edit, status: :unprocessable_entity) unless apply_record_upload_limit_settings(@category)

    if @category.save
      redirect_to edit_admin_category_path(@category), notice: "Category updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @category.destroy
    redirect_to admin_categories_path, notice: "Category deleted."
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :description, :position, :public_read)
  end
end
