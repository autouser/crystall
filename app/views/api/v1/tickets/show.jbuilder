json.status 'success'
json.ticket do
  json.owner        @ticket.user.username if @ticket.user
  if @ticket.project
    json.project do
      json.name @ticket.project.name
      json.id @ticket.project.id
    end
  end
  json.id           @ticket.id
  json.subject      @ticket.subject
  json.content      @ticket.content
  json.status       @ticket.status
end