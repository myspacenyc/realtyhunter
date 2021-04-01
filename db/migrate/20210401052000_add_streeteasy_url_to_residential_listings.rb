class AddStreeteasyUrlToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :streeteasy_url, :string
  end
end
