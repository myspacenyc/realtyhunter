class AddIsThisAMyspacenycHouseListingAndPointOfContactIdLandlords < ActiveRecord::Migration[5.0]
  def change
  	add_column :landlords, :is_this_a_myspacenyc_house_listing, :boolean, default: true
  	add_column :landlords, :point_of_contact_id, :integer
  end
end
