class PrivateMessagesController < ApplicationController
  before_action :require_login
  before_action :set_message, only: %i[show destroy]

  def index
    @messages = PrivateMessage.inbox_for(current_user).page(params[:page])
  end

  def sent
    @messages = PrivateMessage.sent_by(current_user).page(params[:page])
  end

  def show
    authorize_message!
    if @message.recipient == current_user && !@message.read?
      @message.update!(read: true)
      broadcast_message_badge(current_user)
    end
  end

  def new
    @message = PrivateMessage.new
    @message.recipient = User.find_by(id: params[:recipient_id]) if params[:recipient_id]
  end

  def create
    recipient = User.find_by(username: params[:private_message][:recipient_username])
    unless recipient
      @message = PrivateMessage.new(message_params)
      flash.now[:alert] = "Recipient not found."
      return render :new, status: :unprocessable_entity
    end

    @message = PrivateMessage.new(message_params.merge(sender: current_user, recipient: recipient))
    if @message.save
      AttachmentCreator.attach(attachable: @message, user: current_user, files: params[:files])
      broadcast_message
      broadcast_message_badge(recipient)
      redirect_to private_messages_path, notice: "Message sent."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @message.sender == current_user
      @message.update!(sender_deleted: true)
    elsif @message.recipient == current_user
      @message.update!(recipient_deleted: true)
      broadcast_message_badge(current_user)
    end
    redirect_to private_messages_path, notice: "Message deleted."
  end

  private

  def set_message
    @message = PrivateMessage.find(params[:id])
  end

  def authorize_message!
    unless @message.sender == current_user || @message.recipient == current_user
      redirect_to root_path, alert: "Access denied."
    end
  end

  def message_params
    params.require(:private_message).permit(:subject, :body)
  end

  def broadcast_message
    Turbo::StreamsChannel.broadcast_remove_to(@message.recipient, :inbox, target: "empty-inbox")
    Turbo::StreamsChannel.broadcast_prepend_later_to(
      @message.recipient,
      :inbox,
      target: "inbox-messages",
      partial: "private_messages/message_row",
      locals: { message: @message, mailbox: :inbox, row_index: 0 }
    )

    Turbo::StreamsChannel.broadcast_remove_to(@message.sender, :sent_messages, target: "empty-sent")
    Turbo::StreamsChannel.broadcast_prepend_later_to(
      @message.sender,
      :sent_messages,
      target: "sent-messages",
      partial: "private_messages/message_row",
      locals: { message: @message, mailbox: :sent, row_index: 0 }
    )
  end

  def broadcast_message_badge(user)
    Turbo::StreamsChannel.broadcast_replace_later_to(
      user,
      :message_badge,
      target: "message-badge",
      partial: "private_messages/message_badge",
      locals: { user: user }
    )
  end
end
