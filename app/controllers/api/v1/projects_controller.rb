class Api::V1::ProjectsController < Api::V1::BaseController

  load_and_authorize_resource :project

  def index
    @projects = @projects.includes(:user).page(params[:page])
  end

  def create
    @project.user = current_user if current_user
    render status: 400 unless @project.save
  end

  def update
    render status: 400 unless @project.update project_params
  end

  def destroy
    @project.destroy
  end

  def mine
    @projects = @projects.includes(:user).where(user_id: current_user.id).page(params[:page])
    render action: 'index'
  end

private

  def project_params
    params.require(:project).permit(:name, :description, :status)
  end

end
