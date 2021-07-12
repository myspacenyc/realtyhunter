# This module is designed to match StreetEasy's feed format
# http://streeteasy.com/home/feed_format
#
# Our url looks like http:localhost:3000/syndication/1/streeteasy
#
# Todo: before re-enabling caching here, need to figure out how to expire the cache here
# when a building photo is updated. the building photo is displayed before listings photos,
# but adding/removing building photos does not update the listing object.
#cache "streeteasy/#{@listings.ids.join('')}-#{@listings.ids.count}-#{@listings.maximum(:updated_at).to_i}" do


xml.instruct! :xml, :version => "1.0"
#xml.streeteasy :version => "1.6" do
  xml.listings do
  	#exit
	  @listings.each do |listing|

	  	# NOTE: this is super hacky. We should filter this out before sending
	  	# to the view.
	  	# if (!listing.primary_agent_id.blank? or !listing.streeteasy_primary_agent_id.blank?) &&
	  	# 			@primary_agents[listing.unit_id][0].name == @company.name
	  	# 	# skip our generic catch-all account
	  	# 	next
	  	# end
	  	if !@primary_agents[listing.unit_id].blank? &&
	  				@primary_agents[listing.unit_id][0].name == @company.name
	  		# skip our generic catch-all account
	  		next
	  	end

			# if listing.status == "active"
				# @status = "active"
			# elsif listing.status == "pending"
				# @status = "in-contract"
			# elsif listing.status == "off"
			# 	@status == "rented"
			# end

			# listing type
			if listing.r_id
				@ptype = "rental"
			elsif listing.s_id
				@ptype = "sale"
			end

			xml.Listing do #type: @ptype, status: @status, id: listing.listing_id, url: public_url do
				xml.BasicDetails do
					#xml.price listing.rent
					if listing.r_id
						xml.PropertyType "rental"
					elsif listing.s_id
						xml.PropertyType listing.sales_listing.listing_type
					end
					xml.Address listing.street_number + " " + listing.route
					xml.Unit listing.building_unit
					if listing.alt_address
						xml.ALTAddress listing.residential_listing.alt_address
					end
					if listing.streeteasy_unit
						xml.ALTUnit listing.streeteasy_unit
					end
					if listing.status
						xml.Status listing.status
					end
					if listing.rent
						xml.NetPrice listing.rent
					end
					if listing.gross_price
						xml.GrossPrice listing.gross_price
					end
					if listing.r_beds
						xml.Beds listing.r_beds
					end
					if listing.r_baths
						xml.Baths listing.r_baths
					end
					if listing.dimensions
						xml.Dimensions listing.dimensions
					end
					if listing.listing_id
						xml.ListingId listing.listing_id
					end
					if listing.building.landlord
						xml.Landlord listing.building.landlord.code
						xml.LL_Class listing.building.landlord.ll_importance
					end
					if !listing.point_of_contact.nil?
						xml.PointOfContact User.find(listing.point_of_contact).name
					else
						xml.PointOfContact ""
					end
					if !listing.primary_agent_id.nil?
						xml.PrimaryAgent User.find(listing.primary_agent_id).name
					else
						xml.PrimaryAgent ""
					end
					if listing.streeteasy_flag == true || listing.streeteasy_flag_one == true
						xml.OnStreeteasy "Yes"
					else
						xml.OnStreeteasy "No"
					end
					if !listing.youtube_video_url.blank?
						xml.VideoPresentOrNot "Yes"
					else
						xml.VideoPresentOrNot "No"
					end
					if !listing.private_youtube_url.blank?
						xml.PrivateVideoPresentOrNot "Yes"
					else
						xml.PrivateVideoPresentOrNot "No"
					end
					if !listing.tour_3d.blank?
						xml.VideoPresentOrNot3D "Yes"
					else
						xml.VideoPresentOrNot3D "No"
					end
					if listing.available_by
						xml.Available listing.available_by
					end
					xml.neighborhood listing.neighborhood_name
					if listing.has_stock_photos == true
						xml.StockPhotos "Yes"
					else
						xml.StockPhotos "No"
					end
					if !listing.description.blank?
						xml.Description h raw sanitize 	listing.description,
					        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
					else
						xml.Description ""
					end
					public_url = listing.public_url
					if !public_url
						public_url = 'http://www.myspacenyc.com/'
					end
					xml.PublicURL public_url
					xml.zipcode listing.postal_code
					if listing.r_tenant_occupied == true
						xml.TenantOccupied "Yes"
					else
						xml.TenantOccupied "No"
					end
					if listing.access_info
						xml.Access listing.access_info
					end
				end #Basic details
			end # property
		end # listings.each
	end # properties
#end #streeteasy
#end # cache
