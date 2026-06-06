class PostsController < ApplicationController
  before_action :require_login
  before_action :set_thread
  before_action :set_post, only: %i[edit update destroy]

  def create
    service = PostCreator.new(thread: @thread, user: current_user, params: post_params, ip: request.ip)
    @post = service.call

    if @post
      attach_errors = AttachmentCreator.attach(
        attachable: @post,
        user: current_user,
        files: params[:files],
        signed_ids: params[:file_signed_ids]
      )
      broadcast_post
      flash[:alert] = "Some files could not be attached: #{attach_errors.join('; ')}" if attach_errors.any?
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
    @post.assign_attributes(post_params)
    @post.edited_at = Time.current if @post.body_changed?
    if @post.save
      attach_errors = AttachmentCreator.attach(
        attachable: @post,
        user: current_user,
        files: params[:files],
        signed_ids: params[:file_signed_ids]
      )
      flash[:alert] = "Some files could not be attached: #{attach_errors.join('; ')}" if attach_errors.any?
      redirect_to forum_thread_path(@thread, anchor: "post-#{@post.id}"), notice: "Post updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_post!
    AuditLog.record(actor: current_user, action: "delete_post", target: @post,
                    details: "In thread \"#{@thread.title}\"", ip: request.ip) if current_user != @post.user
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

  def broadcast_post
    Turbo::StreamsChannel.broadcast_append_later_to(
      @thread,
      :posts,
      target: "posts",
      partial: "posts/post",
      locals: {
        post: @post,
        thread: @thread,
        post_number: nil,
        viewer: nil,
        can_moderate: false
      }
    )
  end

  def authorize_post!
    unless current_user == @post.user || can_moderate_thread?(@thread)
      redirect_to root_path, alert: "Access denied."
    end
  end
end
