namespace :users do
  desc "Destory all user accounts"
  task destroy_all: :environment do
    User.destroy_all
  end

  desc "Destroy a specific user account"
  task :destroy_user, [:user_email] => [:environment] do |t, args|
    user_email = args[:user_email].to_s
    puts "Destroying user with email: #{user_email}"
    user = User.find_by_email(user_email)
    if user
      puts "User found, destroying user account"
      user.destroy
    else
      puts "User does not exist"
    end
  end
end