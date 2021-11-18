class AddBuildingVideoUrlToBuildings < ActiveRecord::Migration[5.0]
  def change
  	add_column :buildings, :building_youtube_url, :string
  end
end
