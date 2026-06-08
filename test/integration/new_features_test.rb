# frozen_string_literal: true

require "test_helper"

class NewFeaturesTest < ActionDispatch::IntegrationTest
  test "milestones page requires login" do
    get milestones_path
    assert_redirected_to login_path

    sign_in_as(users(:tester))
    get milestones_path
    assert_response :success
    assert_match(/Your Milestones/, response.body)
  end

  test "category show page lists subforums" do
    get category_path(categories(:general))
    assert_response :success
    assert_match(/General Lounge/, response.body)
  end

  test "user can view and acknowledge warnings" do
    warning = UserWarning.create!(
      user: users(:tester),
      warned_by: users(:staff),
      reason: "Please follow upload rules.",
      severity: :moderate
    )

    sign_in_as(users(:tester))
    get user_warnings_path
    assert_response :success
    assert_match(/Please follow upload rules/, response.body)

    patch acknowledge_user_warning_path(warning)
    assert_redirected_to user_warnings_path
    assert warning.reload.acknowledged?
  end

  test "user can report an attachment" do
    post_record = posts(:welcome_post)
    attachment = Attachment.create!(
      attachable: post_record,
      user: users(:staff),
      filename: "report-me.zip",
      content_type: "application/zip",
      byte_size: 10,
      vt_status: "skipped",
      approved: true,
      allowed_content_types: AllowedFileTypes.global_rules[:types]
    )

    sign_in_as(users(:tester))
    assert_difference -> { Report.count }, 1 do
      post reports_path, params: {
        report: {
          reportable_type: "Attachment",
          reportable_id: attachment.id,
          reason: "This upload looks suspicious and may be malware."
        }
      }
    end

    report = Report.order(:id).last
    assert_equal attachment, report.reportable
  end

  test "admin pending files page lists unapproved uploads" do
    post_record = posts(:welcome_post)
    pending = Attachment.create!(
      attachable: post_record,
      user: users(:tester),
      filename: "awaiting.zip",
      content_type: "application/zip",
      byte_size: 10,
      approved: false,
      vt_status: "pending",
      allowed_content_types: AllowedFileTypes.global_rules[:types]
    )

    sign_in_as(users(:staff))
    get admin_pending_files_path
    assert_response :success
    assert_match(/awaiting\.zip/, response.body)
    assert_match(/Files Awaiting Review/, response.body)
    refute pending.approved?
  end

  test "guest can browse threads downloads and public attachment pages" do
    thread = forum_threads(:welcome)
    get forum_thread_path(thread)
    assert_response :success
    assert_match(/Generals Discussion/, response.body)
    assert_match(/Log in/, response.body)

    Badge.stub(:feature_available?, false) do
      get forum_thread_path(thread)
      assert_response :success
      assert_match(/Generals Discussion/, response.body)
    end

    get subforum_path(subforums(:lounge))
    assert_response :success
    assert_match(/Browsing as guest/, response.body)

    get downloads_path
    assert_response :success

    attachment = Attachment.create!(
      attachable: posts(:welcome_post),
      user: users(:staff),
      filename: "command and conquer maps.zip",
      content_type: "application/zip",
      byte_size: 10,
      vt_status: "skipped",
      approved: true,
      allowed_content_types: AllowedFileTypes.global_rules[:types]
    )

    get attachment_path(attachment)
    assert_response :success
    assert_match(/command and conquer maps\.zip/, response.body)
    assert_no_match(/noindex, nofollow/, response.body)

    get download_attachment_path(attachment)
    assert_response :redirect
  end

  test "guest cannot create posts without logging in" do
    thread = forum_threads(:welcome)
    post forum_thread_posts_path(thread), params: { post: { body: "guest spam" } }
    assert_redirected_to login_path
  end

  test "members-only subforum requires login for guests" do
    subforums(:lounge).update!(public_read: false)

    get subforum_path(subforums(:lounge))
    assert_redirected_to login_path
    assert_match(/members only/i, flash[:alert])

    get forum_thread_path(forum_threads(:welcome))
    assert_redirected_to login_path

    sign_in_as(users(:tester))
    get subforum_path(subforums(:lounge))
    assert_response :success

    get forum_thread_path(forum_threads(:welcome))
    assert_response :success
  end

  test "sitemap returns valid xml" do
    get sitemap_path(format: :xml)
    assert_response :success
    assert_includes response.media_type, "xml"
    assert_operator response.body.bytesize, :>, 1000
    assert_match(/<urlset/, response.body)
    refute_match(/<sitemapindex/, response.body)
    assert_match %r{<loc>https?://[^<]+</loc>}, response.body
    assert_match(/public/, response.headers["Cache-Control"])
    assert_nil response.headers["Set-Cookie"]
  end

  test "legacy sitemap urls redirect to forums-sitemap.xml" do
    get "/sitemap.xml"
    assert_redirected_to "/forums-sitemap.xml"

    get "/sitemap_index.xml"
    assert_redirected_to "/forums-sitemap.xml"
  end
end
