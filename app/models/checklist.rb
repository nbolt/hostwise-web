class Checklist < ActiveRecord::Base
  belongs_to :contractor_job, class_name: 'ContractorJobs'
  has_many :contractor_photos

  has_settings do |s|
    s.key :arrival_tasks, defaults: { dishes: false, bathrooms: false }
    s.key :damage_inspection, defaults: { damage: false }
    s.key :inventory_count, defaults: { complete: false, king_sheets: 0, twin_sheets: 0, pillow_count: 0, bath_towels: 0, hand_towels: 0, face_towels: 0, bath_mats: 0 }
    s.key :kitchen, defaults: { fridge: false, dishes: false, dishwasher: false, coffee: false, microwave: false, stove: false, counters: false, toaster: false, trash: false, floor: false }
    s.key :living_room, defaults: { dust: false, tv: false, coffee: false, baseboards: false, mirrors: false, handles: false, furniture: false, floor: false }
    s.key :confirm_details, defaults: { bedrooms: 0, bathrooms: 0, property_type: false }
    s.key :bedroom_1, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bathroom_1, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }

    s.key :bedroom_2, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_3, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_4, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_5, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_6, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_7, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_8, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_9, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }
    s.key :bedroom_10, defaults: { dust: false, trash: false, trash_can: false, fixtures: false, closets: false, windows: false, bed: false, duvet: false, floor: false }

    s.key :bathroom_2, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_3, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_4, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_5, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_6, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_7, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_8, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_9, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
    s.key :bathroom_10, defaults: { shower: false, surfaces: false, sanitize: false, toilet: false, trash: false, mats: false, hair: false, floor: false, restocking: false }
  end

  mount_uploader :kitchen_photo, ContractorPhotoUploader
  mount_uploader :bedroom_photo, ContractorPhotoUploader
  mount_uploader :bathroom_photo, ContractorPhotoUploader

  def checklist_settings
    to_settings_hash
  end
end
