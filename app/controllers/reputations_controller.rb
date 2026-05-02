class ReputationsController < ApplicationController
  before_action :require_login

  def create
    post = Post.find(params[:post_id])
    service = ReputationGiver.new(giver: current_user, post: post, value: params[:value].to_i)
    result = service.call

    if result
      redirect_back fallback_location: root_path, notice: "Reputation given."
    else
      redirect_back fallback_location: root_path, alert: service.errors.join(", ")
    end
  end

  def destroy
    rep = Reputation.find(params[:id])
    if rep.giver == current_user || moderator_or_admin?
      rep.destroy
      redirect_back fallback_location: root_path, notice: "Reputation removed."
    else
      redirect_back fallback_location: root_path, alert: "Access denied."
    end
  end
end
