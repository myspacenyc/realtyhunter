class AddStreeteasyFeaturedToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :streeteasy_featured, :boolean, default: :false
  end
end
