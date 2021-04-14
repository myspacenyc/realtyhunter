class AddTenantCreditOfferedToResidentialListings < ActiveRecord::Migration[5.0]
  def change
  	add_column :residential_listings, :tenant_credit_offered, :boolean, default: false
  end
end
