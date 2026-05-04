class Reputation < ApplicationRecord
  belongs_to :giver, class_name: "User"
  belongs_to :receiver, class_name: "User"
  belongs_to :post, optional: true

  validates :value, inclusion: { in: [ -1, 1 ] }
  validates :giver_id, uniqueness: { scope: %i[receiver_id post_id], message: "already rated this post" }
  validate :cannot_rate_own_post

  after_create :update_receiver_reputation
  after_destroy :revert_receiver_reputation

  private

  def cannot_rate_own_post
    errors.add(:base, "You cannot rate your own post") if giver_id == receiver_id
  end

  def update_receiver_reputation
    receiver.increment!(:reputation, value)
  end

  def revert_receiver_reputation
    receiver.increment!(:reputation, -value)
  end
end
