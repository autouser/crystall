class Api::V1::UsersController < Api::V1::BaseController

  load_and_authorize_resource :user

  def create
    render status: 400 unless @user.save
  end

  def update
    render status: 400 unless @user.update user_params
  end

  def destroy
    @user.destroy
  end

private

  def user_params
    params.require(:user).permit(:username, :password)
  end

end
