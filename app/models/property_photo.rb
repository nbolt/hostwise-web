class PropertyPhoto < ActiveRecord::Base
  belongs_to :property

  mount_uploader :photo, PropertyPhotoUploader
end
