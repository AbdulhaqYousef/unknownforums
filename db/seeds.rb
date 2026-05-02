puts "Seeding database..."

# Use the real site owner account as the author for official seeded posts.
admin = User.find_by(id: 1)
raise "Seed author missing: expected user ID 1 to exist and be username 'terminator'." unless admin
raise "Seed author mismatch: expected user ID 1 to be username 'terminator', got '#{admin.username}'." unless admin.username == "terminator"
puts "Using user ##{admin.id} '#{admin.username}' as seed author"

# Categories and subforums
general = Category.find_or_create_by!(name: "General") do |c|
  c.description = "General discussion topics"
  c.position = 0
end

programming = Category.find_or_create_by!(name: "Programming") do |c|
  c.description = "Programming and development"
  c.position = 1
end

support = Category.find_or_create_by!(name: "Help & Support") do |c|
  c.description = "Get help from the community"
  c.position = 2
end

# Subforums
announce = Subforum.find_or_create_by!(name: "Announcements", category: general) do |s|
  s.description = "Official forum announcements"
  s.position = 0
end

lounge = Subforum.find_or_create_by!(name: "General Lounge", category: general) do |s|
  s.description = "Off-topic general chat"
  s.position = 1
end

ruby_sf = Subforum.find_or_create_by!(name: "Ruby / Rails", category: programming) do |s|
  s.description = "Ruby on Rails discussion"
  s.position = 0
end

js_sf = Subforum.find_or_create_by!(name: "JavaScript", category: programming) do |s|
  s.description = "JavaScript and frontend frameworks"
  s.position = 1
end

help_sf = Subforum.find_or_create_by!(name: "General Help", category: support) do |s|
  s.description = "Ask for help with anything"
  s.position = 0
end

# Announcement threads (pinned + locked = read-only notice boards)
welcome = ForumThread.find_or_create_by!(title: "Welcome to UnknownForums!", subforum: announce) do |t|
  t.user   = admin
  t.pinned = true
  t.locked = true
end
if welcome.posts.empty?
  Post.create!(
    user: admin,
    thread: welcome,
    body: <<~BODY
      Welcome to UnknownForums!

      We're glad you're here. This is a community-driven discussion forum — a place to share ideas, ask questions, and connect with others.

      Before you dive in, please take a moment to read the following:

      • Forum Rules — https://unknownforums.fun/rules
      • Terms of Service — https://unknownforums.fun/terms
      • Privacy Policy — https://unknownforums.fun/privacy

      A few quick tips to get started:
      — Register an account to post and interact with the community
      — Introduce yourself in the General Lounge
      — Use the search bar to see if your question has already been answered
      — Be respectful and have fun

      If you have any issues, feel free to contact a moderator or admin.

      — The UnknownForums Staff
    BODY
  )
end

rules_thread = ForumThread.find_or_create_by!(title: "Forum Rules — Please Read Before Posting", subforum: announce) do |t|
  t.user   = admin
  t.pinned = true
  t.locked = true
end
if rules_thread.posts.empty?
  Post.create!(
    user: admin,
    thread: rules_thread,
    body: <<~BODY
      These rules apply to all members of UnknownForums. Ignorance of the rules is not an excuse. Violations may result in warnings, post removal, or bans.

      GENERAL RULES
      1. Be respectful. No harassment, personal attacks, hate speech, or bullying.
      2. No spam. No advertisements or self-promotion without staff permission.
      3. No NSFW content. Keep it clean.
      4. No illegal content. Do not post anything illegal.
      5. No ban evasion. One account per person.

      POSTING RULES
      1. Stay on topic. Post in the correct subforum.
      2. Use descriptive thread titles.
      3. No double posting. Edit your post instead.
      4. No necroposting threads older than 30 days without something meaningful to add.

      FILE UPLOAD RULES
      1. No malware. Immediate permanent ban.
      2. No pirated content.
      3. Describe what you're uploading.

      ENFORCEMENT
      Verbal warning → post removal → temporary ban → permanent ban.
      Severe violations (malware, threats, doxxing) = immediate permanent ban.

      Full rules: https://unknownforums.fun/rules
    BODY
  )
end

# General threads
if ForumThread.where(subforum: lounge).count.zero?
  intro = ForumThread.create!(title: "Introduce yourself!", user: admin, subforum: lounge, pinned: true)
  Post.create!(user: admin, thread: intro, body: "New here? Drop a message and introduce yourself to the community! Tell us a bit about who you are and what brought you here.")
end

puts "Seeding complete!"
puts "  Author: #{admin.username}"
