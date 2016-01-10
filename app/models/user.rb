class User < ActiveRecord::Base

  include ValidationStatus

  has_secure_password

  has_many :projects, dependent: :destroy
  has_many :tickets,  dependent: :nullify

  validates :username, presence: true, uniqueness: true

end
