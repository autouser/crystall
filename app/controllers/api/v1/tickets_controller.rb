class Api::V1::TicketsController < Api::V1::BaseController

  load_and_authorize_resource :project
  load_and_authorize_resource :ticket, :through => :project

  def index
    @tickets = @tickets.includes(:user).includes(:project).page(params[:page])
  end

  def create
    @ticket.user = current_user if current_user
    render status: 400 unless @ticket.save
  end

  def update
    render status: 400 unless @ticket.update ticket_params
  end

  def destroy
    @ticket.destroy
  end

private

  def ticket_params
    params.require(:ticket).permit(:subject, :content, :status)
  end

end
