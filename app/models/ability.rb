class Ability
  include CanCan::Ability

  def initialize(user)

    user ||= User.new # guest user (not logged in)
    if user.admin
      can :manage, :all
    elsif !user.new_record?
      can [:show, :update, :destroy], User, id: user.id
      can :create, User
      can :me, User

      can [:index, :show, :create], Project
      can [:update, :destroy],      Project, user_id: user.id

      can [:index, :show, :create], Ticket
      can :create,                  Ticket, project: { status: 'open' }
      can [:update, :destroy],      Ticket, user_id: user.id
    else
      can :create, User
      
      can [:index, :show], Project
      can [:index, :show], Ticket
    end
  end
end
