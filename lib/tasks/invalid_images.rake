namespace :invalid_images do
  desc 'Delete all invalid test images -- images that are not associated with a build'
  task :destroy => :environment do

    @dry_run = %w(true 1).include? ENV['DRY_RUN']

    puts "Starting invalid_images:destroy"
    test_images = TestImage.where(build: nil).order("id DESC")
    test_image_count = test_images.size

    if test_image_count == 0
      abort "No invalid images found. Exiting..."
    end

    if @dry_run
      puts "Invalid Images That Would Have Been Deleted: #{test_image_count}"
    else
      test_images.destroy_all
      puts "Successfully Destroyed #{test_image_count} Invalid Test Images"
    end
  end
end
