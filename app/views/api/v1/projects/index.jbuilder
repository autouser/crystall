json.status 'success'
json.projects @projects do |project|
  json.id           project.id
  json.name         project.name
  json.description  project.description
  json.status       project.status
end
json.page @projects.current_page
json.total_pages @projects.total_pages