class PrivateMessage < ApplicationRecord
  belongs_to :sender, class_name: "User"
  belongs_to :recipient, class_name: "User"
  has_many :attachments, as: :attachable, dependent: :destroy

  validates :subject, presence: true, length: { maximum: 200 }
  validates :body, presence: true, length: { minimum: 1, maximum: 10_000 }

  scope :inbox_for, ->(user) { where(recipient: user, recipient_deleted: false).order(created_at: :desc) }
  scope :sent_by, ->(user) { where(sender: user, sender_deleted: false).order(created_at: :desc) }

  after_create  :bust_recipient_unread_cache
  after_update  :bust_recipient_unread_cache
  after_update  :purge_attachments_when_fully_deleted

  paginates_per 25

  private

  def bust_recipient_unread_cache
    recipient&.bust_unread_cache
  end

  def purge_attachments_when_fully_deleted
    return unless sender_deleted? && recipient_deleted?
    return unless saved_change_to_sender_deleted? || saved_change_to_recipient_deleted?

    attachments.includes(:versions).find_each(&:destroy_with_storage!)
  end
end
