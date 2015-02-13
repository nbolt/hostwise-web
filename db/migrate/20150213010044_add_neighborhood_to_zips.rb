class AddNeighborhoodToZips < ActiveRecord::Migration
  def change
    add_reference :zips, :neighborhood, index: true
    add_foreign_key :zips, :neighborhoods
  end
end
