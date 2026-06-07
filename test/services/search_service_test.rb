# frozen_string_literal: true

require "test_helper"

class SearchServiceTest < ActiveSupport::TestCase
  setup do
    enable_pg_trgm!
  end

  test "finds threads despite typos" do
    result = SearchService.new(query: "gnerals").call

    assert result.threads.any?, "expected typo search to match Generals Discussion"
    assert_includes result.threads.map(&:title), forum_threads(:welcome).title
  end

  test "returns featured shortcuts for site keywords" do
    [ "forums", "unknownforums", "unknown forums", "forumsunknown" ].each do |query|
      result = SearchService.new(query: query).call
      assert result.featured.any?, "expected featured shortcut for #{query.inspect}"
      assert_match %r{/(\z|$)}, result.featured.first[:url]
    end
  end

  test "filters posts with attachments only" do
    post = posts(:welcome_post)
    blob = ActiveStorage::Blob.create_and_upload!(
      io: StringIO.new("hello"),
      filename: "notes.txt",
      content_type: "text/plain"
    )
    AttachmentCreator.attach(attachable: post, user: users(:tester), files: nil, signed_ids: [ blob.signed_id ])

    result = SearchService.new(query: "generals", params: { with_attachments: "1" }).call
    assert result.posts.any?
    assert result.posts.all? { |entry| entry.attachments.any? }
  end

  private

  def enable_pg_trgm!
    conn = ActiveRecord::Base.connection
    conn.enable_extension("pg_trgm") unless conn.extension_enabled?("pg_trgm")
  rescue ActiveRecord::StatementInvalid
    skip "pg_trgm extension unavailable"
  end
end
