class ProcessContractorPhotoJob < ActiveJob::Base
  queue_as :default

  def perform(key, id, room)
    ActiveRecord::Base.connection_pool.with_connection do
      url = "https://s3-#{ENV['S3_BUCKET']}.amazonaws.com/hostwise-#{Rails.env}/#{key}"
      checklist = Checklist.find id
      checklist.send "remote_#{room}_photo_url=", url
      if checklist.save
        u = ContractorPhotoUploader.new
        s = CarrierWave::Storage::Fog.new(u)
        f = CarrierWave::Storage::Fog::File.new(u, s, key)
        f.delete if f.exists?
      end
    end
  end
end
