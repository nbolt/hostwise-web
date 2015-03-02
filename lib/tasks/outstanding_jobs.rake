namespace :jobs do
  task process_outstanding: :environment do
    Job.where(status_cd: [0,1,2]).where('bookings.date < ?', Date.today).includes(:booking).references(:booking).each do |job|
      job.past_due!
      job.save
    end
  end
end
