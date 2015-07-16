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

set :output, '/home/dev/workspace/hostwise-web/log/cron_job.log'

# every monday at 12am
every '0 0 * * 1' do
  command "echo '9flats: starting signup...'"
  command "xvfb-run ruby /home/dev/workspace/hostwise-web/spec/tests/9flats_signup_spec.rb"
  command "echo '9flats: completing signup...'"
end

# everyday at 10.30am
every '30 10 * * *' do
  command "echo '9flats: starting blast...'"
  command "xvfb-run ruby /home/dev/workspace/hostwise-web/spec/tests/9flats_blast_spec.rb"
  command "echo '9flats: completing blast...'"
end

