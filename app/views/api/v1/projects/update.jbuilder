json.status (@project.errors.any? ? 'failed' : 'success')
json.project do
  json.id           @project.id if @project.id
  json.owner        @project.user.username if @project.user
  json.name         @project.name
  json.description  @project.description
  json.status       @project.status
  json.errors       @project.errors if @project.errors.any?
end