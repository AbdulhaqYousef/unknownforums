class PostsController < ApplicationController
  before_action :require_login
  before_action :set_thread
  before_action :set_post, only: %i[edit update destroy]

  def create
    service = PostCreator.new(thread: @thread, user: current_user, params: post_params)
    @post = service.call

    if @post
      AttachmentCreator.attach(attachable: @post, user: current_user, files: params[:files])
      redirect_to forum_thread_path(@thread, anchor: "post-#{@post.id}"), notice: "Reply posted."
    else
      redirect_to forum_thread_path(@thread), alert: service.errors.join(", ")
    end
  end

  def edit
    authorize_post!
  end

  def update
    authorize_post!
    if @post.update(post_params)
      AttachmentCreator.attach(attachable: @post, user: current_user, files: params[:files])
      redirect_to forum_thread_path(@thread, anchor: "post-#{@post.id}"), notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_post!
    @post.update!(deleted: true)
    redirect_to forum_thread_path(@thread), notice: "Post deleted."
  end

  private

  def set_thread
    @thread = ForumThread.find(params[:forum_thread_id])
  end

  def set_post
    @post = @thread.posts.find(params[:id])
  end

  def post_params
    params.require(:post).permit(:body, :quote_post_id)
  end

  def authorize_post!
    require_owner_or_moderator(@post.user)
  end
end
