class AddClaimKeyReturnKeyToUnits < ActiveRecord::Migration[5.0]
  def change
  	add_column :units, :unit_claim_key, :boolean, default: false
  	add_column :units, :unit_return_key, :boolean, default: false
  end
end
