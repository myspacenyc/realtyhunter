class AddSwapKeyAgentToUnits < ActiveRecord::Migration[5.0]
  def change
  	add_column :units, :swap_key_agent, :integer
  end
end
