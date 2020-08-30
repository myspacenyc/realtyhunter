class AddTouringOptionsToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :virtual_tours_available, :boolean, default: :false
  	add_column :residential_listings, :in_person_tours_available, :boolean, default: :false
  	add_column :residential_listings, :no_access_until_vacant, :boolean, default: :false
  end
end
