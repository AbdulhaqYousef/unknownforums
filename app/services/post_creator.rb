class PostCreator
  attr_reader :errors, :post

  def initialize(thread:, user:, params:)
    @thread = thread
    @user = user
    @params = params
    @errors = []
  end

  def call
    if @thread.locked? && !@user.can_moderate?
      @errors << "This thread is locked."
      return nil
    end

    @post = @thread.posts.build(@params.merge(user: @user))
    if @post.save
      @post
    else
      @errors = @post.errors.full_messages
      nil
    end
  end
end
