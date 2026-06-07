# frozen_string_literal: true

require "test_helper"

class PostBodyRulesTest < ActiveSupport::TestCase
  test "allows empty body when files are being uploaded" do
    post = posts(:welcome_post).dup
    post.body = ""
    post.allow_empty_body = PostBodyRules.files_in_request?(signed_ids: [ "signed-id" ])

    assert post.valid?, post.errors.full_messages.join(", ")
  end

  test "requires body when no files are attached" do
    post = Post.new(
      thread: forum_threads(:welcome),
      user: users(:tester),
      body: ""
    )

    refute post.valid?
    assert_includes post.errors[:body], "can't be blank"
  end

  test "allows empty body when post already has attachments" do
    post = posts(:welcome_post)
    Attachment.create!(
      attachable: post,
      user: users(:tester),
      filename: "notes.txt",
      content_type: "text/plain",
      byte_size: 10,
      vt_status: "skipped",
      approved: true,
      allowed_content_types: AllowedFileTypes.global_rules[:types]
    )

    post.body = ""
    post.allow_empty_body = PostBodyRules.allow_empty?(post: post)

    assert post.valid?, post.errors.full_messages.join(", ")
  end
end
