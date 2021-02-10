class AddYoutubeUrlToNeighborhoods < ActiveRecord::Migration[5.0]
  def change
  	add_column :neighborhoods, :youtube_url, :string
  end
end
