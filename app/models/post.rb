class Post < ApplicationRecord
  belongs_to :user
  belongs_to :thread, class_name: "ForumThread", foreign_key: :forum_thread_id
  belongs_to :quote_post, class_name: "Post", optional: true
  has_many :attachments, as: :attachable, dependent: :destroy
  has_many :reputations, dependent: :destroy
  has_many :reports, as: :reportable, dependent: :destroy

  validates :body, length: { maximum: 50_000 }, allow_blank: true
  validate :body_present_unless_attachments_allowed

  attr_accessor :allow_empty_body

  scope :visible, -> { where(deleted: false) }

  paginates_per 20

  after_create  :increment_subforum_posts_count
  after_create  :increment_user_posts_count
  after_destroy :decrement_subforum_posts_count
  after_destroy :decrement_user_posts_count
  after_update  :recalculate_visible_counters_after_soft_delete, if: :saved_change_to_deleted?
  after_update  :purge_attachments_after_soft_delete, if: :saved_change_to_deleted?

  def quoted_body
    return nil unless quote_post

    quote_post.body.truncate(500)
  end

  def edited?
    edited_at.present?
  end

  def body_blank?
    body.to_s.strip.blank?
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
    return unless saved_change_to_deleted == [ false, true ]

    thread.update_columns(posts_count: Post.where(forum_thread_id: thread.id, deleted: false).count)
    thread.subforum.update_columns(
      posts_count: Post.joins(:thread).where(forum_threads: { subforum_id: thread.subforum_id }, deleted: false).count
    )
    user.update_columns(posts_count: Post.where(user_id: user.id, deleted: false).count)
    Rails.cache.delete("forum_stats")
  end

  def purge_attachments_after_soft_delete
    return unless saved_change_to_deleted == [ false, true ]

    attachments.includes(:versions).find_each(&:destroy_with_storage!)
  end

  def body_present_unless_attachments_allowed
    return if allow_empty_body
    return if body.to_s.strip.present?

    errors.add(:body, "can't be blank")
  end
end
