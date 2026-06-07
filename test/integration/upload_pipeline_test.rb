# frozen_string_literal: true

require "test_helper"

class UploadPipelineTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @post = posts(:welcome_post)
    @user = users(:tester)
  end

  test "text attachment is auto approved and skips virus scan" do
    blob = active_blob("notes.txt", "text/plain", "hello world")

    errors = AttachmentCreator.attach(
      attachable: @post,
      user: @user,
      files: nil,
      signed_ids: [ blob.signed_id ]
    )

    assert_empty errors
    attachment = @post.attachments.order(:id).last
    assert_equal "skipped", attachment.vt_status
    assert attachment.approved?
    refute attachment.vt_warning_required?
  end

  test "zip attachment queues scan and stays unapproved" do
    blob = active_blob("archive.zip", "application/zip", "PK\x03\x04fake")

    assert_enqueued_with(job: VirusTotalScanJob) do
      errors = AttachmentCreator.attach(
        attachable: @post,
        user: @user,
        files: nil,
        signed_ids: [ blob.signed_id ]
      )
      assert_empty errors
    end

    attachment = @post.attachments.order(:id).last
    assert_equal "pending", attachment.vt_status
    refute attachment.approved?
    assert attachment.vt_warning_required?
  end

  test "malicious unapproved attachment requires download warning" do
    attachment = Attachment.new(
      attachable: @post,
      user: @user,
      filename: "bad.zip",
      content_type: "application/zip",
      byte_size: 12,
      vt_status: "malicious",
      approved: false,
      allowed_content_types: AllowedFileTypes.global_rules[:types]
    )
    attachment.file.attach(
      io: StringIO.new("PK\x03\x04fake"),
      filename: "bad.zip",
      content_type: "application/zip"
    )
    attachment.save!

    assert attachment.vt_warning_required?
  end

  test "approving attachment clears moderation queue state" do
    attachment = Attachment.create!(
      attachable: @post,
      user: @user,
      filename: "pending.zip",
      content_type: "application/zip",
      byte_size: 12,
      vt_status: "pending",
      approved: false,
      allowed_content_types: AllowedFileTypes.global_rules[:types]
    )
    attachment.file.attach(
      io: StringIO.new("PK\x03\x04fake"),
      filename: "pending.zip",
      content_type: "application/zip"
    )

    assert_includes Attachment.pending_approval, attachment
    attachment.update!(approved: true)
    refute_includes Attachment.pending_approval, attachment
  end

  test "destroying attachment enqueues purge of storage blob" do
    blob = active_blob("notes.txt", "text/plain", "delete me")
    errors = AttachmentCreator.attach(
      attachable: @post,
      user: @user,
      files: nil,
      signed_ids: [ blob.signed_id ]
    )
    assert_empty errors

    attachment = @post.attachments.order(:id).last
    assert attachment.file.attached?

    assert_enqueued_with(job: ActiveStorage::PurgeJob) do
      attachment.destroy
    end
  end

  private

  def active_blob(filename, content_type, contents)
    ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new(contents),
      filename: filename,
      content_type: content_type
    )
  end
end
