class AddPendingSeAndManagedListingToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :pending_se, :boolean, default: false
  	add_column :residential_listings, :managed_listing, :boolean, default: false
  end
end
