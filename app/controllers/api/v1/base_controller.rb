class Api::V1::BaseController < ApplicationController

  respond_to :json

  rescue_from CanCan::AccessDenied,               with: :empty_unauthorized
  rescue_from ActiveRecord::RecordNotFound,       with: :empty_notfound
  rescue_from ActionController::ParameterMissing, with: :parameter_missing


  skip_before_filter :verify_authenticity_token

  before_action :authenticate


  def current_user
    @current_user
  end

private

  def authenticate

    authenticate_with_http_basic do |htuser, htpassword|
      user = User.find_by username: htuser
      if user.present? && user.authenticate(htpassword)
        @current_user = user
      end
    end
  end

  def empty_unauthorized
    render nothing: true, status: :unauthorized
  end

  def empty_notfound
    render nothing: true, status: :unauthorized
  end

  def parameter_missing
    render text: 'param is missing or the value is empty', status: 400
  end

  def fix_params
    domain = controller_name.singularize.to_sym
    params[domain] &&= send("#{domain}_params")
  end


end
