class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new # guest user (not logged in)
    if user.admin
      can :manage, :all
    elsif !user.new_record?
      can [:show, :update, :destroy], User, id: user.id
      can :create, User

      can [:index, :show, :create], Project
      can [:update, :destroy], Project, user_id: user.id
    else
      can :create, User
      
      can [:index, :show], Project
    end
  end
end
