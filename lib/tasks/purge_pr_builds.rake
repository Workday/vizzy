namespace :orphaned_pr_builds do
  desc 'Delete builds that are orphaned, aka have no approved diffs (preapprovals) and no new tests (auto approved images)'
  task :destroy => :environment do
    @dry_run = %w(true 1).include? ENV['DRY_RUN']
    builds_destroyed = 0

    non_temporary_pull_requests_older_than_30_days.find_each(batch_size: 500) do |build|
      no_approved_diffs = build.diffs.where(approved: true).size == 0
      no_new_tests = build.new_tests.size == 0
      if no_approved_diffs && no_new_tests
        puts "Deleting build with id: #{build.id}"
        builds_destroyed += 1
        build.destroy unless @dry_run
      end
    end

    if @dry_run
      puts "#{builds_destroyed} builds would have been destroyed"
    else
      puts "#{builds_destroyed} builds successfully destroyed"
    end
  end
end

def non_temporary_pull_requests_older_than_30_days
  Build.where.not(pull_request_number: -1).where(temporary: false).where('created_at < ?', 30.days.ago)
end