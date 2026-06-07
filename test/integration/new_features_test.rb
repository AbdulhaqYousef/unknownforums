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
end
