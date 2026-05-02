namespace :owner do
  desc "Ensure user ID 1 is the terminator admin account"
  task ensure_terminator_id_one: :environment do
    owner = User.find_by(username: "terminator")
    raise "User 'terminator' does not exist. Register it first." unless owner

    id_one = User.find_by(id: 1)

    if id_one && id_one != owner
      raise "Cannot move terminator to ID 1 because ID 1 already belongs to '#{id_one.username}'. Resolve this manually."
    end

    if owner.id != 1
      old_id = owner.id
      User.connection.execute("UPDATE users SET id = 1 WHERE id = #{old_id}")
      User.connection.reset_pk_sequence!("users")
      owner = User.find(1)
    end

    owner.update!(role: :admin)
    puts "Owner ready: user ##{owner.id} #{owner.username} (#{owner.role})"
  end
end
