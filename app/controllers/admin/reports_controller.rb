class Admin::ReportsController < ApplicationController
  before_action :require_moderator
  before_action :set_report, only: %i[show update]

  def index
    @reports = Report.includes(:reporter, :reportable, screenshots_attachments: :blob).joins(:reporter).order(created_at: :desc)
    @reports = @reports.where(status: params[:status]) if params[:status].present?
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      @reports = @reports.where("reports.reason ILIKE :query OR reports.reportable_type ILIKE :query OR users.username ILIKE :query OR users.email ILIKE :query", query: query)
    end
    @reports = @reports.page(params[:page])
  end

  def show
    @report = Report.includes(:reportable).find(params[:id])
  end

  def update
    @report.update!(status: params[:status], resolved_by: current_user)
    redirect_to admin_reports_path, notice: "Report updated."
  end

  private

  def set_report
    @report = Report.find(params[:id])
  end
end
