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

  after_create :increment_subforum_posts_count
  after_destroy :decrement_subforum_posts_count

  def quoted_body
    return nil unless quote_post
    quote_post.body.truncate(500)
  end

  private

  def increment_subforum_posts_count
    thread.subforum.increment!(:posts_count)
  end

  def decrement_subforum_posts_count
    thread.subforum.decrement!(:posts_count)
  end
end
