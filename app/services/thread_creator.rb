class ThreadCreator
  attr_reader :errors

  def initialize(subforum:, user:, thread_params:, post_params:)
    @subforum = subforum
    @user = user
    @thread_params = thread_params
    @post_params = post_params
    @errors = []
  end

  def call
    ActiveRecord::Base.transaction do
      @thread = @subforum.forum_threads.build(@thread_params.merge(user: @user))

      unless @thread.valid?
        @errors = @thread.errors.full_messages
        raise ActiveRecord::Rollback
      end

      @thread.save!

      @post = @thread.posts.build(@post_params.merge(user: @user))

      unless @post.valid?
        @errors = @post.errors.full_messages
        raise ActiveRecord::Rollback
      end

      @post.save!
    end

    @thread&.persisted? ? @thread : nil
  end
end
