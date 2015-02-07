class AddPhoneNumberToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :phone_number, :string
  end
end
