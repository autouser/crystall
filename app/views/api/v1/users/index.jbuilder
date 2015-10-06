json.status 'success'
json.users @users do |user|
  json.id       user.id
  json.username user.username
end
json.page @users.current_page
json.total_pages @users.total_pages