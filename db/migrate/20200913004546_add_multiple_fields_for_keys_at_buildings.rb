class AddMultipleFieldsForKeysAtBuildings < ActiveRecord::Migration[5.0]
  def change
  	add_column :buildings, :building_tag_number, :integer
  	add_column :buildings, :building_key_status, :string
  	add_column :buildings, :building_office_location, :string
  	add_column :buildings, :building_master, :boolean, default: false
  	add_column :buildings, :building_commercial_property, :boolean, default: false
  	add_column :buildings, :building_key_active, :boolean, default: false
  	add_column :buildings, :building_signout_key, :boolean, default: false
  	add_column :buildings, :building_case_name, :string
  end
end
