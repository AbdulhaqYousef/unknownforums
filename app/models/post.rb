class Post < ApplicationRecord
  belongs_to :user
  belongs_to :thread, class_name: "ForumThread", foreign_key: :forum_thread_id, counter_cache: :posts_count
  belongs_to :quote_post, class_name: "Post", optional: true
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :reputations, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  validates :body, presence: true, length: { minimum: 1, maximum: 50_000 }

  scope :visible, -> { where(deleted: false) }

  paginates_per 20

  after_create  :increment_subforum_posts_count
  after_create  :increment_user_posts_count
  after_destroy :decrement_subforum_posts_count
  after_destroy :decrement_user_posts_count
  after_update  :recalculate_visible_counters_after_soft_delete, if: :saved_change_to_deleted?

  def quoted_body
    return nil unless quote_post

    quote_post.body.truncate(500)
  end

  def edited?
    edited_at.present?
  end

  private

  def increment_subforum_posts_count
    thread.subforum.increment!(:posts_count)
  end

  def decrement_subforum_posts_count
    thread.subforum.decrement!(:posts_count)
  end

  def increment_user_posts_count
    user.increment!(:posts_count) unless deleted?
  end

  def decrement_user_posts_count
    user.decrement!(:posts_count) unless deleted?
  end

  def recalculate_visible_counters_after_soft_delete
    return unless saved_change_to_deleted == [false, true]

    thread.update_columns(posts_count: Post.where(forum_thread_id: thread.id, deleted: false).count)
    thread.subforum.update_columns(
      posts_count: Post.joins(:thread).where(forum_threads: { subforum_id: thread.subforum_id }, deleted: false).count
    )
    user.update_columns(posts_count: Post.where(user_id: user.id, deleted: false).count)
    Rails.cache.delete("forum_stats")
  end
end
