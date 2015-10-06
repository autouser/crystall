namespace :crystall do

  desc "Apply admin role to a user"

  task :admin, [ :username ] => :environment do |t, args|
    if args.username
      user = User.find_by username: args.username
      if user
        if user.admin
          puts "User '#{user.username}' is already :admin"
        else
          user.update admin: true
          puts "User '#{user.username}' is :admin now"
        end
      else
        puts "User '#{args.username}' not found"
      end
    else
      puts "username is empty"
    end
  end

  desc "Apply user role to a user"

  task :user, [ :username ] => :environment do |t, args|
    if args.username
      user = User.find_by username: args.username
      if user
        if ! user.admin
          puts "User '#{user.username}' is already :user"
        else
          user.update admin: false
          puts "User '#{user.username}' is :user now"
        end
      else
        puts "User '#{args.username}' not found"
      end
    else
      puts "username is empty"
    end
  end

end
