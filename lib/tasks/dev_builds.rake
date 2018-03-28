desc 'Find dev builds and destroy them'
namespace :dev_builds do
  task destroy: :environment do
    puts 'Destroying dev builds older than 30 days...'
    dev_builds = Build.where(dev_build: true).where('created_at < ?', 30.days.ago)
    dev_build_count = dev_builds.size
    if dev_build_count == 0
      puts 'No dev builds found, nothing to destroy.'
    else
      puts "Destroying #{dev_build_count} dev builds..."
      dev_builds.destroy_all
    end
  end
end
