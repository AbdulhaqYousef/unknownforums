class ReputationGiver
  attr_reader :errors

  def initialize(giver:, post:, value:)
    @giver = giver
    @post = post
    @value = value
    @errors = []
  end

  def call
    unless [-1, 1].include?(@value)
      @errors << "Invalid reputation value"
      return nil
    end

    rep = Reputation.new(
      giver: @giver,
      receiver: @post.user,
      post: @post,
      value: @value
    )

    if rep.save
      rep
    else
      @errors = rep.errors.full_messages
      nil
    end
  end
end
