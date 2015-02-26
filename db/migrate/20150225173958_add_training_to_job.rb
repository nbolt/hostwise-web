class AddTrainingToJob < ActiveRecord::Migration
  def change
    add_column :jobs, :training, :boolean, default: false
  end
end
