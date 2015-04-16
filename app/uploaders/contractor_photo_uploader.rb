class ContractorPhotoUploader < CarrierWave::Uploader::Base

  include CarrierWave::RMagick
  include CarrierWaveDirect::Uploader

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    if Rails.env.test?
      "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    else
      "#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
    end
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  process :auto_orient
  process resize_to_fill: [512, 512]
  process convert: 'png'
  process :set_content_type

  # Create different versions of your uploaded files:
  # version :thumb do
  #   process :resize_to_fit => [50, 50]
  # end

  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg gif png)
  end

  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    if original_filename.present?
      name = super.chomp(File.extname(super))
      name += '__DEV' unless Rails.env == 'production'
      name += '.png' unless name[-4..-1] == '.png'
      return name
    end
  end

  def auto_orient
    manipulate! do |img|
      img = img.auto_orient
    end
  end

  def set_content_type
    self.file.instance_variable_set(:@content_type, 'image/png')
  end

  def will_include_content_type
    true
  end

  default_content_type  'image/png'
end
