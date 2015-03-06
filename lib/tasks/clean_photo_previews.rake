namespace :clean do
  task photo_previews: :environment do
    PhotoPreview.where('created_at < ?', Time.now - 1.day).each do |preview|
      preview.destroy
    end
  end
end
