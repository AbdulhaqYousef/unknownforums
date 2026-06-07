class ForumThreadsController < ApplicationController
  before_action :set_thread, only: %i[show edit update destroy lock unlock pin unpin move bulk_delete_posts]
  before_action :ensure_thread_readable, only: :show
  before_action :require_login, only: %i[new create edit update destroy lock unlock pin unpin move bulk_delete_posts]
  before_action :require_category_staff, only: %i[lock unlock pin unpin move destroy]

  def show
    viewed = session[:viewed_threads] || []
    unless viewed.include?(@thread.id)
      @thread.increment_views!
      session[:viewed_threads] = (viewed + [ @thread.id ]).last(100)
    end
    posts_scope = @thread.posts.visible
                         .includes(:user, :quote_post,
                                   attachments: [ :file_attachment, :versions ],
                                   user: { avatar_attachment: :blob })
                         .order(:created_at)
    if params[:q].present?
      query = "%#{ActiveRecord::Base.sanitize_sql_like(params[:q].strip)}%"
      posts_scope = posts_scope.where("posts.body ILIKE :q", q: query)
    end
    @posts = posts_scope.page(params[:page])
    @post = Post.new
    @thread_attachments = Attachment.where(attachable_type: "Post", attachable_id: @thread.posts.visible.select(:id))
                                    .includes(:file_tags)
    @thread_file_tags = @thread_attachments.flat_map { |attachment| attachment.file_tags.map(&:tag) }.uniq
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
      attach_errors = AttachmentCreator.attach(
        attachable: result.first_post,
        user: current_user,
        files: params[:files],
        signed_ids: params[:file_signed_ids]
      )
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
    require_owner_or_category_staff
  end

  def update
    require_owner_or_category_staff
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
    AuditLog.record(actor: current_user, action: "delete_thread", target: @thread,
                    details: "\"#{@thread.title}\" in #{subforum.name}", ip: request.ip)
    @thread.destroy
    redirect_to subforum_path(subforum), notice: "Thread deleted."
  end

  def lock
    @thread.update!(locked: true)
    AuditLog.record(actor: current_user, action: "lock_thread", target: @thread, ip: request.ip)
    redirect_to forum_thread_path(@thread), notice: "Thread locked."
  end

  def unlock
    @thread.update!(locked: false)
    AuditLog.record(actor: current_user, action: "unlock_thread", target: @thread, ip: request.ip)
    redirect_to forum_thread_path(@thread), notice: "Thread unlocked."
  end

  def pin
    @thread.update!(pinned: true)
    AuditLog.record(actor: current_user, action: "pin_thread", target: @thread, ip: request.ip)
    redirect_to forum_thread_path(@thread), notice: "Thread pinned."
  end

  def unpin
    @thread.update!(pinned: false)
    AuditLog.record(actor: current_user, action: "unpin_thread", target: @thread, ip: request.ip)
    redirect_to forum_thread_path(@thread), notice: "Thread unpinned."
  end

  def move
    new_subforum = Subforum.find(params[:subforum_id])
    @thread.update!(subforum: new_subforum)
    redirect_to forum_thread_path(@thread), notice: "Thread moved."
  end

  def bulk_delete_posts
    require_category_staff
    return redirect_to forum_thread_path(@thread), alert: "No posts selected." if params[:post_ids].blank?

    post_ids = params[:post_ids].map(&:to_i)
    posts    = @thread.posts.where(id: post_ids)
    count    = posts.each { |p| p.update!(deleted: true) }.size
    AuditLog.record(actor: current_user, action: "bulk_delete_posts", target: @thread,
                    details: "Deleted #{count} post(s): IDs #{post_ids.join(', ')}", ip: request.ip)
    redirect_to forum_thread_path(@thread), notice: "#{count} post(s) deleted."
  end

  private

  def set_thread
    @thread = ForumThread.includes(subforum: :category).find(params[:id])
  end

  def ensure_thread_readable
    ensure_subforum_readable!(@thread.subforum)
  end

  def require_category_staff
    unless can_moderate_thread?(@thread)
      redirect_to root_path, alert: "Access denied."
    end
  end

  def require_owner_or_category_staff
    unless current_user == @thread.user || can_moderate_thread?(@thread)
      redirect_to root_path, alert: "Access denied."
    end
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
