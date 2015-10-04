json.status (@user.errors.any? ? 'failed' : 'success')
json.user do
  json.id       @user.id if @user.id
  json.username @user.username
  json.errors @user.errors if @user.errors.any?
end