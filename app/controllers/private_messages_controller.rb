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
    @message.update!(read: true) if @message.recipient == current_user && !@message.read?
    authorize_message!
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
end
