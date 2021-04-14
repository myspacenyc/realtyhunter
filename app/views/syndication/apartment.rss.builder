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
xml.PhysicalProperty do
	xml.Management do
		xml.Identification do
			xml.OrganizationName "Myspacenyc"
		end
	end
  #xml.properties do
  	#exit
	  @listings.where.not(status: 1).each do |listing|

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
				@status = "active"
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

			public_url = listing.public_url
			if !public_url
				public_url = 'http://www.myspacenyc.com/'
			end

			xml.property do #type: @ptype, status: @status, id: listing.listing_id, url: public_url
				xml.PropertyID do
					xml.Identification IDType: "PrimaryID" do
						xml.IDValue listing.id
					end
					xml.WebSite public_url
					xml.Address AddressType: "other" do
						xml.Address listing.street_number + " " + listing.route
						xml.City listing.sublocality
						xml.State listing.administrative_area_level_1_short
						xml.PostalCode listing.postal_code
						if !listing.primary_agent_id.nil?
							user = User.find(listing.primary_agent_id)
							xml.Email @primary_agents[listing.unit_id].first.streeteasy_email
						end
					end
					xml.Phone PhoneType: "office" do
						xml.PhoneNumber "9292748181"
					end
				end
				xml.ILS_Identification RentalType: "Unspecified", ILS_IdentificationType: "Apartment" do
					xml.Latitude listing.building.lat
					xml.Longitude listing.building.lng
				end
				xml.Information do

				end
				# xml.location do
				# 	# note we don't want to give out the building number for rentals!
				# 	xml.address listing.street_number + " " + listing.route
				# 	xml.apartment listing.building_unit
				# 	xml.city listing.sublocality
				# 	xml.state listing.administrative_area_level_1_short
				# 	xml.zipcode listing.postal_code
				# 	xml.neighborhood listing.neighborhood_name
				# end

				# xml.details do
				# 	xml.price listing.rent

				#  	if !listing.has_fee
				#  		xml.noFee
				#  	end

				# 	if listing.exclusive
				# 		xml.exclusive
				# 	end

				# 	if !listing.r_beds.nil?
				# 		xml.bedrooms listing.r_beds.to_i
				# 	elsif !listing.s_beds.nil?
				# 		xml.bedrooms listing.s_beds.to_i
				# 	end

				# 	if listing.r_total_room_count
			 #        	xml.totalrooms listing.r_total_room_count.to_i
			 #        end
			 #        if listing.s_total_room_count
			 #        	xml.totalrooms listing.s_total_room_count.to_i
			 #        end

				# 	baths = nil
				# 	if !listing.r_baths.nil?
				# 		baths = listing.r_baths
				# 	elsif !listing.s_baths.nil?
				# 		baths = listing.s_baths
				# 	end

				# 	if baths
				# 		xml.bathrooms baths.floor.to_i
				# 		decimal_idx = baths.to_s.index('.5')
				# 		if !decimal_idx.nil?
				# 			xml.half_baths 1
				# 		end
				# 	end

				# 	xml.availableOn listing.available_by # rentals only

				# 	if listing.r_id
				# 		xml.description h raw sanitize listing.description,
		  #       		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
		  #     elsif listing.s_id
		  #       xml.description h raw sanitize listing.public_description,
		  #       		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
				# 	end

				# 	if listing.r_id
				# 		xml.propertyType "rental"
				# 	elsif listing.s_id
				# 		xml.propertyType "house"
				# 	end
					# xml.propertyType @ptype

					# streeteasy has their own approved list of amenities
					# doorman, gym, pool, elevator, garage, parking, balcony, storage, patio, fireplace
					# washerDryer, dishwasher, furnished, pets, other
					#xml.amenities do

						@other_amenities = []
						attribute_found = {}
						if @building_amenities[listing.building_id]
							@building_amenities[listing.building_id].map{|b| b.name}.each do |bm|
								case bm
									when "doorman"
										xml.Amenity AmenityType: "Doorman" do
											xml.Description "doorman"
										end
									when "gym", "fitness center", "sauna"
										if !attribute_found["gym"]
											attribute_found["gym"] = 1
											xml.Amenity AmenityType: "gym" do
												xml.Description "Gym"
											end
										end
									when "pool"
										xml.Amenity AmenityType: "Pool" do
											xml.Description "Pool"
										end
									when "elevator"
										xml.Amenity AmenityType: "Elevator" do
											xml.Description "Elevator"
										end
									when "garage parking"
										xml.Amenity AmenityType: "Garage" do
											xml.Description "Garage"
										end
									when "parking", "parking for $200 a month"
										if !attribute_found["parking"]
											attribute_found["parking"] = 1
											xml.Amenity AmenityType: "Parking" do
												xml.Description "Parking"
											end
										end
									when "balcony"
										xml.Amenity AmenityType: "Balcony" do
											xml.Description "Balcony"
										end
									when "storage"
										xml.Amenity AmenityType: "Storage" do
											xml.Description "Storage"
										end
									when "courtyard", "shared yard for building"
										if !attribute_found["patio"]
											attribute_found["patio"] = 1
											xml.Amenity AmenityType: "Patio" do
												xml.Description "Patio" # outdoor space ?
											end
										end
									when "fireplace"
										xml.Amenity AmenityType: "Fireplace" do
											xml.Description Fireplace
										end
									# when "laundry in building"
									# 	if !attribute_found["washerDryer"]
									# 		attribute_found["washerDryer"] = 1
									# 		xml.washerDryer
									# 	end
									# 	@laundry_included = true
									else
										@other_amenities << bm
								end # case
							end
						end

						# pets_allowed = ["case by case",  "cats only", "cats/small dogs", "dogs only", "monthly pet fee" ,
						# 		"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
						# if @pet_policies[listing.building_id] && pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
						# 	xml.pets
						# end

						if @residential_amenities && @residential_amenities[listing.unit_id]
							@residential_amenities[listing.unit_id].map{|a| a.name}.each do |rm|

								case rm
									when "balcony/terrace"
										xml.Amenity AmenityType: "Balcony" do
											xml.Description "Balcony"
										end
									when "storage", "basement"
										xml.Amenity AmenityType: "Storage" do
											xml.Description "Storage"
										end
									when "private yard", "shared yard"
										xml.Amenity AmenityType: "Patio" do
											xml.Description "Patio" # outdoor space ?
										end
									when "washer/dryer hookups", "washer/dryer in unit"
										if !attribute_found["washerDryer"]
											attribute_found["washerDryer"] = 1
											xml.Amenity AmenityType: "WasherDryer" do
												xml.Description "WasherDryer"
											end
										end
									when "dishwasher"
										xml.Amenity AmenityType: "Dishwasher" do
											xml.Description "Dishwasher"
										end
									when "furnished"
										xml.Amenity AmenityType: "Furnished" do
											xml.Description "Furnished"
										end
									else
										if !attribute_found[rm]
											attribute_found[rm] = 1
											@other_amenities << rm
										end
								end # case

							end
						end

						if !@other_amenities.blank?
							@other_amenities.each do |am|
								xml.Amenity AmenityType: "Other" do
									xml.Description am
								end
							end
						end
						pets_allowed = ["case by case",  "cats only", "cats/small dogs", "dogs only", "monthly pet fee" ,
								"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
						if @pet_policies[listing.building_id] && pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
							xml.pets
							if ["cats only"].include?(@pet_policies[listing.building_id][0].pet_policy_name)
								xml.Policies do
									xml.Pet allowed: true do
										xml.Pets PetType: "Cat"
									end
								end
							elsif ["cats/small dogs"].include?(@pet_policies[listing.building_id][0].pet_policy_name)
								xml.Policies do
									xml.Pet allowed: true do
										xml.Pets PetType: "Cat"
									end
									xml.Pet allowed: true do
										xml.Pets PetType: "Dog"
									end
								end
							elsif ["dogs only"].include?(@pet_policies[listing.building_id][0].pet_policy_name)
								xml.Policies do
									xml.Pet allowed: true do
										xml.Pets PetType: "Dog"
									end
								end
							else
								xml.Policies do
									xml.Pet allowed: true do
										xml.Pets PetType: "Pets"
									end
								end
							end
						end

					#end # amenities
				end # details

				if !@open_houses[listing.unit_id].blank?
					xml.openHouses do
						@open_houses[listing.unit_id].each do |oh|
							xml.openHouse do
								# must match this format: 2006-11-20 3:30pm
								xml.startsAt oh.day.strftime("%Y-%m-%d") + " " + oh.start_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
								xml.endsAt oh.day.strftime("%Y-%m-%d") + " " + oh.end_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
								xml.apptOnly
							end
						end
					end
				end

				if  !listing.primary_agent_id.blank? || !listing.streeteasy_primary_agent_id.blank?
					xml.agents do
						# On all residential listings, set the company account as the first "agent".
            # This is used for accounting purposes, as Streeteasy charges a fee per ad.
            # if listing.listing_id = 3207478
            # 	abort Unit.where(listing_id: listing.listing_id)[0].residential_listing.inspect
            # end
            if listing.r_id
				#unit = Unit.where(listing_id: listing.listing_id)[0].residential_listing
				#abort listing.residential_listing.inspect
				if listing.residential_listing.streeteasy_flag == true
	              xml.agent id: 114 do
	                xml.name "Myspace NYC"
	                xml.email "info+streeteasy@myspacenyc.com"
	                xml.lead_email "info+streeteasy@myspacenyc.com"
	                xml.phone_numbers do
	                  xml.office "9292748181"
	                end
	              end
	              	if !listing.primary_agent_id.nil?
	              		agent = User.find(listing.primary_agent_id)
						xml.agent id: agent.id do
							xml.name agent.name
							xml.company @company.name
							if @agent_images[agent.id]
								xml.photo url:@agent_images[agent.id].file.url(:large)
							end
						  # xml.url agent.public_url
							xml.email agent.streeteasy_email
							xml.lead_email agent.streeteasy_email
							xml.phone_numbers do
								xml.main agent.streeteasy_mobile_number
								xml.office agent.office.telephone
								xml.cell agent.streeteasy_mobile_number
								xml.fax agent.office.fax
							end
						end
					end
	            end
				if listing.residential_listing.streeteasy_flag_one == true
					user = User.find(listing.streeteasy_primary_agent_id)
					xml.agent id: user.id do
						xml.name user.name
						xml.company @company.name
						if user.image
							xml.photo url:user.image.file.url(:large)
						end
					xml.email user.streeteasy_email
					xml.lead_email user.streeteasy_email
					xml.phone_numbers do
						xml.main user.streeteasy_mobile_number
						xml.office user.office.telephone
						xml.cell user.streeteasy_mobile_number
						xml.fax user.office.fax
					end
					end
				end
            end # end forced
					end
				end

				xml.media do
					if @bldg_images[listing.building_id]
						@bldg_images[listing.building_id].each do |i|
							xml.photo url:i.file.url(:large), position: i.priority, description:""
						end
					end
					if @images[listing.unit_id]
						@images[listing.unit_id].each do |i|
							xml.photo url:i.file.url(:large), position: i.priority, description:""
						end
					end
				end

			end # property
		end # listings.each
	#end # properties
#end #streeteasy
#end # cache
