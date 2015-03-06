class PhotoPreview < ActiveRecord::Base
  mount_uploader :photo, PropertyPhotoUploader
end
