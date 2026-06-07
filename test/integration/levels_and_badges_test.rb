# frozen_string_literal: true

require "test_helper"

class LevelsAndBadgesTest < ActionDispatch::IntegrationTest
  test "admin can manage badges and user level" do
    sign_in_as(users(:administrator))

    get admin_badges_path
    assert_response :success
    assert_match(/Badges/, response.body)

    assert_difference -> { Badge.count }, 1 do
      post admin_badges_path, params: {
        badge: { name: "OG Member", description: "Early supporter", position: 1 }
      }
    end
    badge = Badge.order(:id).last
    assert_equal "OG Member", badge.name

    user = users(:tester)
    get edit_admin_user_path(user)
    assert_response :success

    patch admin_user_path(user), params: {
      user: { experience_points: 250, level_override: 5, reputation: user.reputation, role: user.role }
    }
    assert_redirected_to admin_user_path(user)
    user.reload
    assert_equal 250, user.experience_points
    assert_equal 5, user.level
    assert_equal 5, user.level_override

    assert_difference -> { UserBadge.count }, 1 do
      post admin_user_user_badges_path(user), params: { badge_id: badge.id }
    end
    assert_redirected_to admin_user_path(user)
    assert user.badges.include?(badge)
  end

  test "posting awards experience points" do
    user = users(:tester)
    thread = forum_threads(:welcome)
    before_xp = user.experience_points

    sign_in_as(user)
    assert_difference -> { Post.count }, 1 do
      post forum_thread_posts_path(thread), params: { post: { body: "Level up test reply" } }
    end

    assert user.reload.experience_points >= before_xp + User::XP_PER_POST
  end

  test "user profile shows level and badges" do
    user = users(:tester)
    badge = Badge.create!(name: "Tester Badge", description: "For tests", position: 0)
    UserBadge.create!(user: user, badge: badge, awarded_at: Time.current)
    user.update!(experience_points: 150)

    get user_path(user)
    assert_response :success
    assert_match(/Level 2/, response.body)
    assert_match(/150 XP/, response.body)
    assert_match(/Tester Badge/, response.body)
  end

  test "linear leveling uses 100 xp per level" do
    user = users(:tester)
    user.update!(experience_points: 99, level_override: nil)
    assert_equal 1, user.level
    assert_equal 1, user.xp_to_next_level

    user.update!(experience_points: 100)
    assert_equal 2, user.level
    assert_equal 0, user.level_progress_percent
  end

  test "user profile edit includes custom badge upload" do
    user = users(:tester)
    sign_in_as(user)

    get edit_user_path(user)
    assert_response :success
    assert_match(/Your Badge GIF/, response.body)

    user.custom_badge.attach(
      io: StringIO.new("GIF89a"),
      filename: "mine.gif",
      content_type: "image/gif"
    )
    assert user.has_display_badges?

    get user_path(user)
    assert_response :success
    assert_match(/mine\.gif|user-badge-img/, response.body)
  end
end
