json.status 'success'
json.projects @projects do |project|
  json.id           project.id
  json.name         project.name
  json.description  project.description
  json.status       project.status
end