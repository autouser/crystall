class Project < ActiveRecord::Base

  belongs_to :user

  validates :name,    presence:   true
  validates :name,    uniqueness: true

  validates :status,  inclusion:  {in: ['open', 'closed']}

  validates :user,    presence:   true


end
