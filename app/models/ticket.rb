class Ticket < ActiveRecord::Base

  belongs_to :user
  belongs_to :project

  validates :content,   presence: true

  validates :status,  inclusion: {in: ['open', 'closed', 'finished']}

  validates :project,   presence: true

  validates :user,      presence: true

  validate :project_validator

  before_validation :assign_status

private

  def assign_status
    self.status ||= 'open'
  end

  def project_validator
    if self.project && (self.project.user_id != self.user_id) && (self.project.status == 'closed')
      errors.add(:project, "is closed")
    end
  end


end
