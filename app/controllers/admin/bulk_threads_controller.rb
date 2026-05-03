class Admin::BulkThreadsController < ApplicationController
  before_action :require_admin

  def update
    thread_ids = Array(params[:thread_ids]).map(&:to_i).reject(&:zero?)
    return redirect_back(fallback_location: admin_root_path, alert: "No threads selected.") if thread_ids.empty?

    threads = ForumThread.where(id: thread_ids)

    case params[:bulk_action]
    when "lock"
      threads.update_all(locked: true)
      redirect_back fallback_location: admin_root_path, notice: "#{threads.count} thread(s) locked."
    when "unlock"
      threads.update_all(locked: false)
      redirect_back fallback_location: admin_root_path, notice: "#{threads.count} thread(s) unlocked."
    when "pin"
      threads.update_all(pinned: true)
      redirect_back fallback_location: admin_root_path, notice: "#{threads.count} thread(s) pinned."
    when "unpin"
      threads.update_all(pinned: false)
      redirect_back fallback_location: admin_root_path, notice: "#{threads.count} thread(s) unpinned."
    when "delete"
      threads.destroy_all
      redirect_back fallback_location: admin_root_path, notice: "#{thread_ids.size} thread(s) deleted."
    when "move"
      subforum = Subforum.find_by(id: params[:target_subforum_id])
      return redirect_back(fallback_location: admin_root_path, alert: "Invalid subforum.") unless subforum
      threads.update_all(subforum_id: subforum.id)
      redirect_back fallback_location: admin_root_path, notice: "#{threads.count} thread(s) moved to #{subforum.name}."
    else
      redirect_back fallback_location: admin_root_path, alert: "Unknown action."
    end
  end
end
