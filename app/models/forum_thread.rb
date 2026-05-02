class ForumThread < ApplicationRecord
  belongs_to :user
  belongs_to :subforum, counter_cache: :threads_count
  has_many :posts, foreign_key: :forum_thread_id, dependent: :destroy
  has_many :attachments, as: :attachable, dependent: :destroy

  validates :title, presence: true, length: { minimum: 3, maximum: 200 }

  scope :pinned_first, -> { order(pinned: :desc, created_at: :desc) }

  paginates_per 30

  def increment_views!
    increment!(:views_count)
  end

  def first_post
    posts.order(:created_at).first
  end

  def last_post
    posts.where(deleted: false).order(:created_at).last
  end
end
