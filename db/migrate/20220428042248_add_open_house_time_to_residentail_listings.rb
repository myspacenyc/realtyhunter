class AddOpenHouseTimeToResidentailListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :open_house_times, :string
  end
end
