class Subforum < ApplicationRecord
  include FileTypeRestrictions

  belongs_to :category
  has_many :forum_threads, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def last_post
    Post.joins(:thread)
        .where(forum_threads: { subforum_id: id }, deleted: false)
        .order(created_at: :desc)
        .first
  end
end
