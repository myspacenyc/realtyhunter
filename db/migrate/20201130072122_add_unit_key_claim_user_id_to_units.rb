class AddUnitKeyClaimUserIdToUnits < ActiveRecord::Migration[5.0]
  def change
  	add_column :units, :unit_key_claim_user_id, :integer
  end
end
