json.status 'success'
json.project do
  json.id           @project.id
  json.owner        @project.user.username if @project.user
  json.name         @project.name
  json.description  @project.description
  json.status       @project.status
end