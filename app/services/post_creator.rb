class PostCreator
  attr_reader :errors, :post

  def initialize(thread:, user:, params:, ip: nil, files: nil, signed_ids: nil)
    @thread = thread
    @user = user
    @params = params
    @ip = ip
    @files = files
    @signed_ids = signed_ids
    @errors = []
  end

  def call
    if @thread.locked? && !@user.can_moderate?
      @errors << "This thread is locked."
      return nil
    end

    @post = @thread.posts.build(@params.merge(user: @user, ip_address: @ip))
    @post.allow_empty_body = PostBodyRules.files_in_request?(files: @files, signed_ids: @signed_ids)
    if @post.save
      @user.award_post_xp!
      ThreadSubscription.subscribe!(user: @user, thread: @thread)
      NotificationDispatcher.dispatch_for_post(@post)
      Trophy.check_and_award!(@user)
      SpamDetector.check!(@post)
      @post
    else
      @errors = @post.errors.full_messages
      nil
    end
  end
end
