class Project < ActiveRecord::Base

  belongs_to :user
  has_many   :tickets, dependent: :destroy

  validates :name,    presence:   true
  validates :name,    uniqueness: true

  validates :status,  inclusion:  {in: ['open', 'closed']}

  validates :user,    presence:   true


end
