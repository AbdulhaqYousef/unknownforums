class LeaderboardsController < ApplicationController
  def index
    # Cache leaderboard data for 5 minutes to avoid heavy queries on every request
    @top_posters = Rails.cache.fetch("leaderboard/top_posters", expires_in: 5.minutes) do
      User.order(posts_count: :desc, created_at: :asc).limit(10).to_a
    end

    @top_reputation = Rails.cache.fetch("leaderboard/top_reputation", expires_in: 5.minutes) do
      User.order(reputation: :desc, posts_count: :desc).limit(10).to_a
    end

    @top_uploaders = Rails.cache.fetch("leaderboard/top_uploaders", expires_in: 5.minutes) do
      top_uploaders
    end

    @top_downloaders = Rails.cache.fetch("leaderboard/top_downloaders", expires_in: 5.minutes) do
      top_downloaders
    end

    @top_files = Rails.cache.fetch("leaderboard/top_files", expires_in: 5.minutes) do
      Attachment.public_downloads.approved.includes(:user).top_downloads.limit(10).to_a
    end
  end

  private

  def top_uploaders
    counts = Attachment.group(:user_id).count.sort_by { |_user_id, count| -count }.first(10)
    users = User.where(id: counts.map(&:first)).index_by(&:id)
    counts.filter_map { |user_id, count| [ users[user_id], count ] if users[user_id] }
  end

  def top_downloaders
    counts = Attachment.group(:user_id).sum(:download_count).sort_by { |_user_id, count| -count }.first(10)
    users = User.where(id: counts.map(&:first)).index_by(&:id)
    counts.filter_map { |user_id, count| [ users[user_id], count ] if users[user_id] }
  end
end
