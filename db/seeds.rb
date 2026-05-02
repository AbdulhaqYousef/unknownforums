puts "Seeding database..."

# Admin user
admin = User.find_or_create_by!(username: "admin") do |u|
  u.email = "admin@forums.local"
  u.password = "admin1234"
  u.password_confirmation = "admin1234"
  u.role = :admin
  u.reputation = 500
end
puts "Admin user: #{admin.username}"

# Moderator user
mod = User.find_or_create_by!(username: "moderator") do |u|
  u.email = "mod@forums.local"
  u.password = "mod12345"
  u.password_confirmation = "mod12345"
  u.role = :moderator
  u.reputation = 100
end

# Sample user
user = User.find_or_create_by!(username: "member1") do |u|
  u.password = "member123"
  u.password_confirmation = "member123"
  u.role = :user
end

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

# Sample threads and posts
if ForumThread.count.zero?
  thread1 = ForumThread.create!(
    title: "Welcome to the Forums!",
    user: admin,
    subforum: announce,
    pinned: true
  )
  Post.create!(body: "Welcome everyone! This is the official forum. Please read the rules before posting.", user: admin, thread: thread1)
  Post.create!(body: "Thanks for setting this up! Looking forward to being part of the community.", user: user, thread: thread1)

  thread2 = ForumThread.create!(
    title: "Introduce yourself here",
    user: mod,
    subforum: lounge
  )
  Post.create!(body: "Hey everyone, use this thread to introduce yourself to the community!", user: mod, thread: thread2)

  thread3 = ForumThread.create!(
    title: "Best practices for Ruby on Rails performance",
    user: user,
    subforum: ruby_sf
  )
  Post.create!(body: "I wanted to start a discussion about Rails performance tips. What are your go-to optimization techniques?\n\nI usually start with:\n- Adding proper database indexes\n- Using counter caches\n- Avoiding N+1 queries with includes()", user: user, thread: thread3)
  Post.create!(body: "Great topic! I always make sure to use bullet gem during development to catch N+1 queries early.", user: mod, thread: thread3)
end

puts "Seeding complete!"
puts "  Admin: admin / admin1234"
puts "  Mod:   moderator / mod12345"
puts "  User:  member1 / member123"
