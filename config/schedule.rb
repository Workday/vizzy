# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever

# Destroy all dev builds every day
every 1.day do
  rake 'dev_builds:destroy', environment: 'production'
end

# Destroy leaf pr builds every day
every 1.day do
  rake 'orphaned_pr_builds:destroy', environment: 'production'
end

# Destroy images that are not attached to a record every month
every 1.month do
  rake 'paperclip:clean_orphan_files', environment: 'production'
end
