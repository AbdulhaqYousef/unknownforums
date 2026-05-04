class MilestonesController < ApplicationController
  before_action :require_login

  def index
    @milestones = milestone_definitions
    @achieved = @milestones.select { |milestone| milestone[:current] >= milestone[:target] }
    @challenges = @milestones.reject { |milestone| milestone[:current] >= milestone[:target] }
  end

  private

  def milestone_definitions
    uploaded_files = Attachment.where(user: current_user).count
    file_downloads = Attachment.where(user: current_user).sum(:download_count)
    clean_files = Attachment.where(user: current_user, vt_status: "clean").count
    account_days = ((Time.current - current_user.created_at) / 1.day).floor
    watched_threads = current_user.thread_subscriptions.count
    sent_messages = current_user.sent_messages.count

    [
      milestone("First Post", "Make your first post or reply.", current_user.posts_count, 1, "posts"),
      milestone("Active Poster", "Reach 10 visible posts.", current_user.posts_count, 10, "posts"),
      milestone("Forum Regular", "Reach 100 visible posts.", current_user.posts_count, 100, "posts"),
      milestone("Reputation Starter", "Earn 10 reputation.", current_user.reputation, 10, "rep"),
      milestone("Trusted Member", "Earn 100 reputation.", current_user.reputation, 100, "rep"),
      milestone("First Upload", "Upload your first file.", uploaded_files, 1, "files"),
      milestone("File Contributor", "Upload 10 files.", uploaded_files, 10, "files"),
      milestone("Verified Uploader", "Get 5 clean VirusTotal file results.", clean_files, 5, "clean files"),
      milestone("Popular Files", "Receive 25 downloads on your uploads.", file_downloads, 25, "downloads"),
      milestone("Hot Uploader", "Receive 100 downloads on your uploads.", file_downloads, 100, "downloads"),
      milestone("Watcher", "Watch 5 threads.", watched_threads, 5, "watched"),
      milestone("Messenger", "Send 10 private messages.", sent_messages, 10, "messages"),
      milestone("One Week Member", "Keep your account for 7 days.", account_days, 7, "days"),
      milestone("Veteran Account", "Keep your account for 30 days.", account_days, 30, "days")
    ]
  end

  def milestone(title, description, current, target, unit)
    current_value = current.to_i
    target_value = target.to_i
    {
      title: title,
      description: description,
      current: current_value,
      target: target_value,
      unit: unit,
      percent: target_value.positive? ? [ ((current_value.to_f / target_value) * 100).round, 100 ].min : 100
    }
  end
end
