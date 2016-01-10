class Api::V1::UsersController < Api::V1::BaseController

  load_and_authorize_resource :user

  def index
    @users = @users.page(params[:page])
  end

  def create
    render status: 400 unless @user.save
  end

  def update
    render status: 400 unless @user.update user_params
  end

  def destroy
    @user.destroy
  end

  def me
    if current_user.present?
      @user = current_user
    else
      render status: 401
    end
  end

private

  def user_params
    params.require(:user).permit(:username, :password)
  end

end
