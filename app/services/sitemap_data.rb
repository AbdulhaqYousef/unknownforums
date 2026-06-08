# frozen_string_literal: true

class SitemapData
  def self.load
    subforums = readable_subforums.includes(:category).order(:position, :name)
    {
      subforums: subforums,
      threads: ForumThread.joins(:subforum)
                          .where(subforum_id: subforums.select(:id))
                          .includes(:subforum)
                          .order(updated_at: :desc)
                          .limit(5000),
      users: User.where(banned: false).order(updated_at: :desc).limit(2000),
      attachments: readable_attachments
                     .where(parent_attachment_id: nil)
                     .order(updated_at: :desc)
                     .limit(5000)
    }
  end

  def self.readable_subforums
    return Subforum.publicly_readable if subforum_access_columns?

    Subforum.all
  end

  def self.readable_attachments
    scope = Attachment.approved.public_downloads
    return scope.in_readable_subforums(nil) if subforum_access_columns?

    scope
  end

  def self.subforum_access_columns?
    Subforum.column_names.include?("public_read") && Category.column_names.include?("public_read")
  end
  private_class_method :subforum_access_columns?
end
