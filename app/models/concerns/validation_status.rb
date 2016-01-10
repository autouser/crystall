module ValidationStatus
  extend ActiveSupport::Concern
  def validation_status
    self.errors.any? ? 'failed' : 'success'
  end
end