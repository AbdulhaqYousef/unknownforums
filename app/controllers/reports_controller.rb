class ReportsController < ApplicationController
  before_action :require_login

  def new
    @report = Report.new
    @reportable_type = params[:reportable_type]
    @reportable_id = params[:reportable_id]
  end

  def create
    klass = Report::REPORTABLE_TYPES.find { |k| k == params[:report][:reportable_type] }
    unless klass
      redirect_to root_path, alert: "Invalid report type."
      return
    end

    reportable = klass.constantize.find(params[:report][:reportable_id])
    @report = Report.new(report_params.merge(reporter: current_user, reportable: reportable))

    if @report.save
      redirect_back fallback_location: root_path, notice: "Report submitted. Thank you."
    else
      @reportable_type = params[:report][:reportable_type]
      @reportable_id = params[:report][:reportable_id]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def report_params
    params.require(:report).permit(:reason, screenshots: [])
  end
end
