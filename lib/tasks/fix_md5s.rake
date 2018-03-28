desc 'Verify that the md5s in the database match the actual md5 of the image'
task :fix_md5s => :environment do
    @dry_run = %w(true 1).include? ENV['DRY_RUN']

    puts "Finding images with mismatched md5s"
    images_updated = 0
    TestImage.find_each do |test_image|
        file_md5 = Digest::MD5.file(test_image.image.path).hexdigest
        db_md5 = test_image.md5
        if db_md5 != file_md5 
            images_updated += 1
            if !@dry_run 
                test_image.md5 = file_md5
                test_image.save
            end
        end
    end
    if @dry_run
        puts "Would have updated #{images_updated} md5s"
    else
        puts "Updated #{images_updated} md5s"
    end
end

