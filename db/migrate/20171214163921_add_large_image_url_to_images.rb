class AddLargeImageUrlToImages < ActiveRecord::Migration[5.0]
  def change
  	add_column :images, :large_image_url, :string
  end
end
