class ContractorPhoto < ActiveRecord::Base
  belongs_to :checklist

  mount_uploader :photo, ContractorPhotoUploader
end
