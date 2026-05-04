class ForumThreadsController < ApplicationController
  before_action :set_thread, only: %i[show edit update destroy lock unlock pin unpin move]
  before_action :require_login
  before_action :require_moderator, only: %i[lock unlock pin unpin move destroy]

  def show
    @thread.increment_views!
    @posts = @thread.posts.visible
                    .includes(:user, :quote_post,
                              attachments: [:file_attachment, :versions],
                              user: { avatar_attachment: :blob })
                    .order(:created_at)
                    .page(params[:page])
    @post = Post.new
    @subscription = logged_in? && ThreadSubscription.find_by(user: current_user, forum_thread: @thread)
    @subscription&.mark_read!
  end

  def new
    @subforum = Subforum.find(params[:subforum_id])
    @thread = ForumThread.new
    @post = Post.new
  end

  def create
    @subforum = Subforum.find(params[:subforum_id])
    service = ThreadCreator.new(
      subforum: @subforum,
      user: current_user,
      thread_params: thread_params,
      post_params: post_params
    )

    result = service.call
    if result
      attach_errors = AttachmentCreator.attach(attachable: result.first_post, user: current_user, files: params[:files])
      flash[:alert] = "Some files could not be attached: #{attach_errors.join('; ')}" if attach_errors.any?
      redirect_to forum_thread_path(result), notice: "Thread created."
    else
      @thread = ForumThread.new(thread_params)
      @post = Post.new(post_params)
      flash.now[:alert] = service.errors.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    require_owner_or_moderator(@thread.user)
  end

  def update
    require_owner_or_moderator(@thread.user)
    @thread.assign_attributes(thread_update_params)
    @thread.edited_at = Time.current if @thread.title_changed?
    if @thread.save
      redirect_to forum_thread_path(@thread), notice: "Thread updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    subforum = @thread.subforum
    @thread.destroy
    redirect_to subforum_path(subforum), notice: "Thread deleted."
  end

  def lock
    @thread.update!(locked: true)
    redirect_to forum_thread_path(@thread), notice: "Thread locked."
  end

  def unlock
    @thread.update!(locked: false)
    redirect_to forum_thread_path(@thread), notice: "Thread unlocked."
  end

  def pin
    @thread.update!(pinned: true)
    redirect_to forum_thread_path(@thread), notice: "Thread pinned."
  end

  def unpin
    @thread.update!(pinned: false)
    redirect_to forum_thread_path(@thread), notice: "Thread unpinned."
  end

  def move
    new_subforum = Subforum.find(params[:subforum_id])
    @thread.update!(subforum: new_subforum)
    redirect_to forum_thread_path(@thread), notice: "Thread moved."
  end

  private

  def set_thread
    @thread = ForumThread.find(params[:id])
  end

  def thread_params
    params.require(:forum_thread).permit(:title)
  end

  def thread_update_params
    params.require(:forum_thread).permit(:title)
  end

  def post_params
    params.require(:post).permit(:body, :quote_post_id)
  end
end
