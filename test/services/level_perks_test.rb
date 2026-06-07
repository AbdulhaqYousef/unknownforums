# frozen_string_literal: true

require "test_helper"

class LevelPerksTest < ActiveSupport::TestCase
  test "upload tiers pick highest qualifying tier" do
    user = users(:tester)
    user.update!(experience_points: 450)

    assert_equal 5, user.level
    assert_equal (0.5 * 1.gigabyte).to_i, LevelPerks.max_upload_bytes_for(user)
  end

  test "custom badge requires configured level" do
    user = users(:tester)
    user.update!(experience_points: 0)
    refute LevelPerks.custom_badge_allowed?(user)

    user.update!(experience_points: 500)
    assert LevelPerks.custom_badge_allowed?(user)
  end

  test "gif avatar requires configured level" do
    user = users(:tester)
    user.update!(experience_points: 100)
    refute LevelPerks.gif_avatar_allowed?(user)

    user.update!(experience_points: 300)
    assert LevelPerks.gif_avatar_allowed?(user)
  end

  test "user upload cap applies to forum rules" do
    user = users(:tester)
    user.update!(experience_points: 0)
    subforum = subforums(:lounge)
    capped = UploadLimits.max_bytes_for_subforum(subforum, user: user)
    assert capped <= LevelPerks.max_upload_bytes_for(user)
  end
end
