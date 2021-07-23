# todo: before re-enabling caching here, need to figure out how to expire the cache here
# when a building photo is updated. the building photo is displayed before listings photos,
# but adding/removing building photos does not update the listing object.
#cache "naked_apts/#{@listings.ids.join('')}-#{@listings.ids.count}-#{@listings.maximum(:updated_at).to_i}" do

# url looks like <base_url>/syndication/1/naked_apts
xml.instruct! :xml, :version => "1.0"
xml.streeteasy :version => "1.6" do
  xml.properties do

	  @listings.each do |listing|

	  	# status should always be reported as active
	  	# translate status
	  	@status = 'active'
			# if listing.status == "active"
			# 	@status = "active"
			# elsif listing.status == "pending"
			# 	@status = "off-market"
			# elsif listing.status == "offer_submitted"
			# 	@status = "contract-out"
			# elsif listing.status == "offer_accepted"
			# 	@status = "in-contract"
		 #  elsif listing.status == "binder_signed"
			# 	@status = "contract-signed"
			# elsif listing.status == "off" ||
			# 	listing.status == "rented"
			# end

			# listing type
			if listing.r_id
				@ptype = "rental"
			# else sales
			# @ptype = "sale"
			end

			xml.property type: @ptype, status: @status, id: listing.listing_id, url: listing.public_url do
				xml.location do
					# note we don't want to give out the building number for rentals!
					if listing.residential_listing
						if	!listing.residential_listing.alt_address.blank?
	                  		xml.address listing.residential_listing.alt_address
	                  	else
	                  		xml.address listing.street_number + " " + listing.route
	                  	end
					end
					xml.apartment listing.building_unit
					xml.city listing.sublocality
					xml.state listing.administrative_area_level_1_short
					xml.zipcode listing.postal_code
					xml.neighborhood listing.neighborhood_name
				end

				xml.details do
					if !listing.promotional_price.nil?
	                  xml.price listing.promotional_price
	                else
	                  xml.price listing.rent
	                end

				 	if !listing.has_fee
				 		xml.noFee
				 	end

					if listing.exclusive
						xml.exclusive
					end

					if listing.r_beds
						xml.bedrooms listing.r_beds
					elsif listing.s_beds
						xml.bedrooms listing.s_beds
					end

					if listing.r_total_room_count
						xml.totalrooms listing.r_total_room_count
					end

					baths = nil
					if listing.r_baths
						baths = listing.r_baths
					elsif listing.s_baths
						baths = listing.s_baths
					end

					if baths
						xml.bathrooms baths.floor.to_i

						decimal_idx = baths.to_s.index('.5')
						if !decimal_idx.nil?
							xml.half_baths 1
						end
					end

					xml.availableOn listing.available_by # rentals only

					if listing.r_id
						xml.description h raw sanitize listing.description,
		        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
		      elsif listing.s_id
		        xml.description h raw sanitize listing.public_description,
		        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
					end

					xml.propertyType "rental"

					# 	if @pet_policies[listing.building_id]
					# 		xml.pets @pet_policies[listing.building_id][0].pet_policy_name
					# 	else
					# 		xml.pets nil
					# 	end

					# streeteasy has their own approved list of amenities
					# doorman, gym, pool, elevator, garage, parking, balcony, storage, patio, fireplace
					# washerDryer, dishwasher, furnished, pets, other
					xml.amenities do

						@other_amenities = []
						attribute_found = {}
						if @building_amenities[listing.building_id]
							@building_amenities[listing.building_id].map{|b| b.name}.each do |bm|
								case bm
									when "doorman"
										xml.doorman
									when "gym", "fitness center", "sauna"
										if !attribute_found["gym"]
											attribute_found["gym"] = 1
											xml.gym
										end
									when "pool"
										xml.pool
									when "elevator"
										xml.elevator
									when "garage parking"
										xml.garage
									when "parking", "parking for $200 a month"
										if !attribute_found["parking"]
											attribute_found["parking"] = 1
											xml.parking
										end
									when "balcony"
										xml.balcony
									when "storage"
										xml.storage
									when "courtyard", "shared yard for building"
										if !attribute_found["patio"]
											attribute_found["patio"] = 1
											xml.patio # outdoor space ?
										end
									when "fireplace"
										xml.fireplace
									when "laundry in building"
										if !attribute_found["washerDryer"]
											attribute_found["washerDryer"] = 1
											xml.washerDryer
										end
										@laundry_included = true
									else
										@other_amenities << bm
								end # case
							end
						end

						if @residential_amenities && @residential_amenities[listing.unit_id]
							@residential_amenities[listing.unit_id].map{|a| a.name}.each do |rm|

								case rm
									when "balcony/terrace"
										xml.balcony
									when "storage", "basement"
										xml.storage
									when "private yard", "shared yard"
										xml.patio # outdoor space ?
									when "washer/dryer hookups", "washer/dryer in unit"
										if !attribute_found["washerDryer"]
											attribute_found["washerDryer"] = 1
											xml.washerDryer
										end
									when "dishwasher"
										xml.dishwasher
									when "furnished"
										xml.furnished
									else
										if !attribute_found[rm]
											attribute_found[rm] = 1
											@other_amenities << rm
										end
								end # case

							end
						end

						if !@other_amenities.blank?
							xml.other @other_amenities.join(", ")
						end
					end # amenities

					pets_allowed = ["case by case",  "cats only", "cats/small dogs", "dogs only", "monthly pet fee" ,
	            "pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
	        if @pet_policies[listing.building_id] && pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
	          xml.pets
	        end

				end # details

				if !@open_houses[listing.unit_id].blank?
					xml.openHouses do
						@open_houses[listing.unit_id].each do |oh|
							xml.openHouse do
								# must match this format: 2006-11-20 3:30pm
								xml.startsAt oh.day.strftime("%Y-%m-%d") + " " + oh.start_time.strftime("%I:%M%p")
								xml.endsAt oh.day.strftime("%Y-%m-%d") + " " + oh.end_time.strftime("%I:%M%p")
								xml.apptOnly
							end
						end
					end
				end

				if !@primary_agents[listing.unit_id].blank?
					xml.agents do
						xml.agent id: 114 do
		                xml.name "Myspace NYC"
		                xml.email "info+streeteasy@myspacenyc.com"
		                xml.lead_email "info+streeteasy@myspacenyc.com"
		                xml.phone_numbers do
		                  xml.office "9292748181"
		                end
		            end

						if !listing.residential_listing.claim_for_naked_apartment.blank?
							listing.residential_listing.claim_for_naked_apartment.each do |agent|
								user = User.find(agent.to_i)
								xml.agent id: user.id do
									xml.name user.name
									xml.company @company.name
									if !user.image.nil?
										xml.photo user.image.file.url(:large)
									end
									xml.email user.email
									xml.lead_email user.email
									xml.phone_numbers do
										xml.main user.mobile_phone_number
										xml.office user.office.telephone
										xml.cell user.mobile_phone_number
										xml.fax user.office.fax
									end
								end
							end
						end
					end
				end

				xml.media do
					if @bldg_images[listing.building_id]
						@bldg_images[listing.building_id].each do |i|
							xml.photo url: i.file.url(:large), position: i.priority
						end
					end
					if @images[listing.unit_id]
						@images[listing.unit_id].each do |i|
							xml.photo url: i.file.url(:large), position: i.priority
						end
					end
					if @images[listing.unit_id]
						@images[listing.unit_id].each do |i|
							if i.floorplan == true
								xml.floorplan url:i.file.url(:large), description:""
							end
						end
					end
				end

			end # property
		end # listings.each
	end # properties
end #naked_apts
#end # cache
