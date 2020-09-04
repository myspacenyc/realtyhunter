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
xml.streeteasy :version => "1.6" do
  xml.properties do
  	#exit
	  # @builds = Building.where(push_to_zumper: true, archived: false).where("description <> ''")

			# 	if !@builds.blank?
			# 		@builds.each do |listing|
			# 			if !listing.images.blank?
			# 				arr_build = []
			# 				cond_for_building = listing.units.where(status: 0, archived: false)
			# 				cond_for_building.each do |cond_build|
			# 					arr_build << cond_build.images.where(floorplan: true)
			# 				end
			# 				if !arr_build.blank?
			# 					if !listing.neighborhood.blank?
			# 						public_url = "https://myspacenyc.com/rentals-building/" + (listing.street_number + "-" + listing.route.downcase.tr(" ", "-") + "-" + listing.neighborhood.name.downcase.tr(" ", "-") + "-" + listing.sublocality.downcase.tr(" ", "-") + "-" + listing.administrative_area_level_1_short.downcase)
			# 					end

			# 					if !listing.building_website.blank?
			# 						public_url = listing.building_website
			# 					end

			# 					xml.property type: "building", status: "active", id: listing.id, url: public_url do
			# 							xml.location do
			# 								# note we don't want to give out the building number for rentals!
			# 								xml.address listing.street_number + " " + listing.route
			# 								# if !listing.streeteasy_unit.nil?
			# 								# 	xml.apartment listing.streeteasy_unit
			# 								# else
			# 								# 	xml.apartment listing.building_unit
			# 								# end
			# 								xml.city listing.sublocality
			# 								xml.state listing.administrative_area_level_1_short
			# 								xml.zipcode listing.postal_code
			# 								xml.neighborhood listing.neighborhood.name
			# 							end
			# 							if !listing.images.blank?
			# 								xml.media do
			# 									listing.images.each do |image|
			# 										xml.photo url: image.file.url(:large)
			# 									end
			# 								end
			# 							end
			# 							xml.details do
			# 								#xml.price listing.rent

			# 							 	# if !listing.has_fee
			# 							 	# 	xml.noFee
			# 							 	# end
			# 							 	if listing.building_name
			# 							 		xml.name listing.building_name
			# 							 	end

			# 							 	if listing.featured == true
			# 							 		xml.featured "yes"
			# 							 	else
			# 							 		xml.featured "no"
			# 							 	end

			# 							 	xml.pets do
			# 							 		cats_allowed = ["case by case",  "cats only", "cats/small dogs", "monthly pet fee",
			# 												"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
			# 									if cats_allowed.include?(listing.pet_policy.name)
			# 										xml.cats
			# 									end
			# 									dogs_allowed = ["case by case", "cats/small dogs", "dogs only", "monthly pet fee" ,
			# 												"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
			# 									if dogs_allowed.include?(listing.pet_policy.name)
			# 										xml.dogs
			# 									end
			# 							 	end
			# 							 	xml.misc do
			# 							 		if listing.section_8 == true
			# 							 			xml.section_8
			# 							 		end
			# 							 		if listing.income_restricted == true
			# 							 			xml.income_restricted
			# 							 		end
			# 							 	end
			# 							 	xml.lease_duration "1 Year"
			# 							 	if !listing.description.blank?
			# 							 		xml.description h raw sanitize listing.description,
			# 					         		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
			# 							 	end

			# 							 	xml.amenities do

			# 										@other_amenities = []
			# 										attribute_found = {}
			# 										# abort listing.building_amenities.inspect
													
			# 										if listing.building_amenities
			# 											if (listing.building_amenities.map(&:name) & ["conference room", "business lounge"]).empty? == false
			# 												xml.business_center
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["24 hour concierge", "valet", "concierge", "4 hour front desk concierge", "concierge/services"]).empty? == false
			# 												xml.concierge_service
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["doorman"]).empty? == false
			# 												xml.door_person
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["elevator"]).empty? == false
			# 												xml.elevator
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["basketball court", "climbing wall", "fitness center", "pool", "squash court", "swimming pool", "yoga room"]).empty? == false
			# 												xml.fitness_center
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["parking", "garage parking", "parking for $200 a month"]).empty? == false
			# 												xml.garage_parking
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["laundry in building", "w/d in unit"]).empty? == false
			# 												xml.onsite_laundry

			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["live in super", "24 hour concierge", "24 hour front desk concierge", "24 hour security"]).empty? == false
			# 												xml.onsite_management
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["community garden", "dog run", "grills", "courtyard", "outdoor spaces", "shared backyard", "outdoor movie screening", "balconies", "outdoor areas"]).empty? == false
			# 												xml.outdoor_space
			# 											end													
			# 											if (listing.building_amenities.map(&:name) & ["package room"]).empty? == false
			# 												xml.package_service
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["recreation", "lounge", "communal spaces"]).empty? == false
			# 												xml.residents_lounge
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["roof access", "roof top terrace", "roof deck", "rooftop pet run"]).empty? == false
			# 												xml.roof_deck
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["24 hour security", "doorman", "virtual doorman", "video intercom"]).empty? == false
			# 												xml.secured_entry
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["bike storage", "cold storage", "storage"]).empty? == false
			# 												xml.storage
			# 											end
			# 											if (listing.building_amenities.map(&:name) & ["pool", "swimming pool"]).empty? == false
			# 												xml.swimming_pool
			# 											end															
			# 										end
			# 									end
			# 							end # details

			# 							xml.agents do
			# 								agent = User.find(listing.point_of_contact)
			# 								xml.agent id: agent.id do
			# 									xml.name agent.name
			# 									xml.company "MySpace NYC"
			# 									xml.photo agent.image.file.url(:large)
			# 									xml.email agent.streeteasy_email
			# 									xml.lead_email agent.streeteasy_email
			# 									xml.phone_numbers do
			# 										xml.main agent.streeteasy_mobile_number
			# 										xml.office agent.office.telephone
			# 										xml.cell agent.streeteasy_mobile_number
			# 										xml.fax agent.office.fax
			# 									end
			# 								end
			# 							end

			# 							xml.floorplans do
			# 								uns = listing.units.where(status: 0, archived: false)
			# 								uns.each do |unit|
			# 									un = unit.images.where(floorplan: true)
			# 									if !un.blank?
			# 										un.each do |a|
			# 											xml.floorplan id: unit.id do
			# 												xml.nane unit.building_unit
			# 												xml.status unit.status
			# 												xml.bedrooms unit.residential_listing.beds
			# 												xml.bathrooms unit.residential_listing.baths
			# 												xml.reant unit.rent
			# 												xml.media do
			# 													xml.photo a.file.url(:large)
			# 												end
			# 											end
			# 										end
			# 									end
			# 								end
			# 							end
			# 						end # property
			# 					end
			# 				end
			# 			end
			# 	end
	  @listings.each do |listing|

	  	# NOTE: this is super hacky. We should filter this out before sending
	  	# to the view.
	  	# if (!listing.primary_agent_id.blank? or !listing.streeteasy_primary_agent_id.blank?) &&
	  	# 			@primary_agents[listing.unit_id][0].name == @company.name
	  	# 	# skip our generic catch-all account
	  	# 	next
	  	# end
	  	if !listing.images.blank?
		  	if !@primary_agents[listing.unit_id].blank? &&
		  				@primary_agents[listing.unit_id][0].name == @company.name
		  		# skip our generic catch-all account
		  		next
		  	end

				# if listing.status == "active"
					if listing.r_id
						@status = "active"
					else
						if listing.status == "on_market"
							@status = "On Market"
						elsif listing.status == "offer_submitted"
							@status = "Offer Submitted"
						elsif listing.status == "contract_out"
							@status = "Contract Out"
						elsif listing.status == "in_escrow"
							@status = "In Escrow"
						end
					end
				# elsif listing.status == "pending"
					# @status = "in-contract"
				# elsif listing.status == "off"
				# 	@status == "rented"
				# end

				# listing type
				if listing.r_id
					# if listing.residential_listing.roomshare_department == false
					# 	@ptype = "rental"
					# elsif listing.residential_listing.roomshare_department == true
					# 	@ptype = "room"
					# end
				elsif listing.s_id
					@ptype = "sale"
				end

				public_url = listing.public_url
				if !public_url
					public_url = 'http://www.myspacenyc.com/'
				end

				if listing.residential_listing
					if listing.residential_listing.roomshare_department == false
						xml.property type: "rental", status: "active", id: listing.listing_id, url: public_url do
							xml.location do
								# note we don't want to give out the building number for rentals!
								if listing.building.push_to_zumper == true
									if !listing.building.building_name.blank?
										xml.building_name listing.building.building_name
									else
										xml.building_name listing.route
									end
								end
								if	!listing.residential_listing.alt_address.blank?
			                  		xml.address listing.residential_listing.alt_address
			                  	else
									xml.address listing.street_number + " " + listing.route
								end
								if !listing.streeteasy_unit.nil?
									xml.apartment listing.streeteasy_unit
								else
									xml.apartment listing.building_unit
								end
								xml.city listing.sublocality
								xml.state listing.administrative_area_level_1_short
								xml.zipcode listing.postal_code
								xml.neighborhood listing.neighborhood_name
							end

							xml.details do
								if listing.building.push_to_zumper == true
									xml.provider_buildingid listing.building.id
								end
								xml.price listing.rent

							 	if !listing.has_fee
							 		xml.noFee
							 	end

							 	if listing.featured == true
							 		xml.featured "yes"
							 	else
							 		xml.featured "no"
							 	end

								if listing.exclusive
									xml.exclusive
								end

								if listing.internal_sq_footage
									xml.squareFeet listing.internal_sq_footage
								end

								if !listing.r_beds.nil?
									if listing.r_beds.is_a?(Float) && (listing.r_beds.to_i == listing.r_beds)
										xml.bedrooms listing.r_beds.to_i
									else
										xml.bedrooms listing.r_beds
									end
								elsif !listing.s_beds.nil?
									xml.bedrooms listing.s_beds
								end

								if listing.r_total_room_count
						        	xml.totalrooms listing.r_total_room_count.to_i
						        end
						        if listing.s_total_room_count
						        	xml.totalrooms listing.s_total_room_count.to_i
						        end

								baths = nil
								if !listing.r_baths.nil?
									baths = listing.r_baths
								elsif !listing.s_baths.nil?
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

								pb_description = ""
								if listing.building.landlord
									if !listing.building.landlord.ll_public_description.nil?
										pb_description = listing.building.landlord.ll_public_description
									end
								end
								b_description = ""
								if listing.building
									if !listing.building.description.blank?
										b_description = listing.building.description
									end
								end
								t_description = ""
								if !listing.residential_listing.tenant_description.nil?  && !listing.residential_listing.tenant_description.blank?
									t_description = "Tenant Quote " + listing.residential_listing.tenant_description
								end

								if listing.r_id
									xml.description h raw sanitize t_description + " " + b_description + " " + listing.description + " " + pb_description,
					        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
					      elsif listing.s_id
					        xml.description h raw sanitize listing.public_description,
					        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
								end

								if listing.r_id
									xml.propertyType "rental"
								elsif listing.s_id
									xml.propertyType listing.sales_listing.listing_type
								end
								# xml.propertyType @ptype
								if listing.property_tax
									xml.taxes listing.property_tax
								end
								if listing.common_chargers
									xml.maintenance listing.common_chargers
								end
								# streeteasy has their own approved list of amenities
								# doorman, gym, pool, elevator, garage, parking, balcony, storage, patio, fireplace
								# washerDryer, dishwasher, furnished, pets, other
								if listing.s_id
									#xml.amenities listing.sales_listing.sales_amenities.map(&:name).join(",")
									xml.amenities do
										@other_amenities = []
										listing.sales_listing.sales_amenities.map{|a| a.name}.each do |rm|

											case rm
												when "dishwasher"
													xml.dishwasher
												when "patio"
													xml.patio
												when "pets allowed"
													xml.pets
												when "fireplace"
													xml.fireplace
												else
													@other_amenities << rm
											end
										end
										if !@other_amenities.blank?
											xml.other @other_amenities.join(", ")
										end
									end
								else
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

										pets_allowed = ["case by case",  "cats only", "cats/small dogs", "dogs only", "monthly pet fee" ,
												"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
										if @pet_policies[listing.building_id] && pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
											xml.pets
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

									end
								end # amenities
							end # details

							if !@open_houses[listing.unit_id].blank?
								xml.openHouses do
									@open_houses[listing.unit_id].each do |oh|
										xml.openHouse do
											# must match this format: 2006-11-20 3:30pm
											xml.startsAt oh.day.strftime("%Y-%m-%d") + " " + oh.start_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
											xml.endsAt oh.day.strftime("%Y-%m-%d") + " " + oh.end_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
											if listing.s_id
												if oh.appt_only == true
													xml.apptOnly
												end
											end
											if !listing.s_id
												xml.apptOnly
											end
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
							if !listing.primary_agent_id.nil?
									user = User.find(listing.primary_agent_id)

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

							# if listing.residential_listing.streeteasy_flag == true
				   #            xml.agent id: 114 do
				   #              xml.name "Myspace NYC"
				   #              xml.email "info+streeteasy@myspacenyc.com"
				   #              xml.lead_email "info+streeteasy@myspacenyc.com"
				   #              xml.phone_numbers do
				   #                xml.office "9292748181"
				   #              end
				   #            end
				   #            @primary_agents[listing.unit_id].each do |agent|
							# 		xml.agent id: agent.id do
							# 			xml.name agent.name
							# 			xml.company @company.name
							# 			if @agent_images[agent.id]
							# 				xml.photo url:@agent_images[agent.id].file.url(:large)
							# 			end
							# 		  # xml.url agent.public_url
							# 		xml.email agent.streeteasy_email
							# 		xml.lead_email agent.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main agent.streeteasy_mobile_number
							# 			xml.office agent.office_telephone
							# 			xml.cell agent.streeteasy_mobile_number
							# 			xml.fax agent.office_fax
							# 		end
							# 		end
							# 	end
				   #          end
							# if listing.residential_listing.streeteasy_flag_one == true
							# 	if listing.streeteasy_primary_agent_id
							# 		user = User.find(listing.streeteasy_primary_agent_id)

							# 		xml.agent id: user.id do
							# 			xml.name user.name
							# 			xml.company @company.name
							# 			if user.image
							# 				xml.photo url:user.image.file.url(:large)
							# 			end

							# 		xml.email user.streeteasy_email
							# 		xml.lead_email user.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main user.streeteasy_mobile_number
							# 			xml.office user.office.telephone
							# 			xml.cell user.streeteasy_mobile_number
							# 			xml.fax user.office.fax
							# 		end
							# 	end
							# 	end
							# 	if !listing.primary_agent2_id.nil?
							# 		user = User.find(listing.primary_agent2_id)

							# 		xml.agent id: user.id do
							# 			xml.name user.name
							# 			xml.company @company.name
							# 			if user.image
							# 				xml.photo url:user.image.file.url(:large)
							# 			end

							# 		xml.email user.streeteasy_email
							# 		xml.lead_email user.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main user.streeteasy_mobile_number
							# 			xml.office user.office.telephone
							# 			xml.cell user.streeteasy_mobile_number
							# 			xml.fax user.office.fax
							# 		end
							# 	end
							# 	end
							# end
			            else

			            	if !listing.primary_agent_id.nil?
									user = User.find(listing.primary_agent_id)

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
							# if listing.sales_listing.streeteasy_flag == true
				   #            xml.agent id: 114 do
				   #              xml.name "Myspace NYC"
				   #              xml.email "info+streeteasy@myspacenyc.com"
				   #              xml.lead_email "info+streeteasy@myspacenyc.com"
				   #              xml.phone_numbers do
				   #                xml.office "9292748181"
				   #              end
				   #            end
				   #            @primary_agents[listing.unit_id].each do |agent|
							# 		xml.agent id: agent.id do
							# 			xml.name agent.name
							# 			xml.company @company.name
							# 			if @agent_images[agent.id]
							# 				xml.photo url:@agent_images[agent.id].file.url(:large)
							# 			end
							# 		  # xml.url agent.public_url
							# 		xml.email agent.streeteasy_email
							# 		xml.lead_email agent.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main agent.streeteasy_mobile_number
							# 			xml.office agent.office_telephone
							# 			xml.cell agent.streeteasy_mobile_number
							# 			xml.fax agent.office_fax
							# 		end
							# 		end
							# 	end
				   #          end
			            end # end forced
								end
							end

							xml.media do
								if !listing.youtube_video_url.blank?
									xml.video url: listing.youtube_video_url, description: "Take a virtual tour of #{listing.street_number + " " + listing.route}"
								end
								if @bldg_images[listing.building_id]
									@bldg_images[listing.building_id].each do |i|
										xml.photo url:i.file.url(:large), position: i.priority, description:""
									end
								end
								if @images[listing.unit_id]
									@images[listing.unit_id].each do |i|
										if i.floorplan != true
											xml.photo url:i.file.url(:large), position: i.priority, description:""
										end
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
					end

					if listing.residential_listing.roomshare_department == true && listing.status == "active"
						xml.property type: "rental", status: "active", id: listing.listing_id, url: public_url do
							xml.location do
								# note we don't want to give out the building number for rentals!
								if listing.building.push_to_zumper == true
									if !listing.building.building_name.blank?
										xml.building_name listing.building.building_name
									else
										xml.building_name listing.route
									end
								end
								if	!listing.residential_listing.alt_address.blank?
			                  		xml.address listing.residential_listing.alt_address
			                  	else
									xml.address listing.street_number + " " + listing.route
								end
								if !listing.streeteasy_unit.nil?
									xml.apartment listing.streeteasy_unit
								else
									xml.apartment listing.building_unit
								end
								xml.city listing.sublocality
								xml.state listing.administrative_area_level_1_short
								xml.zipcode listing.postal_code
								xml.neighborhood listing.neighborhood_name
							end

							xml.details do
								if listing.building.push_to_zumper == true
									xml.provider_buildingid listing.building.id
								end
								xml.price listing.rent

							 	if !listing.has_fee
							 		xml.noFee
							 	end

							 	if listing.featured == true
							 		xml.featured "yes"
							 	else
							 		xml.featured "no"
							 	end

								if listing.exclusive
									xml.exclusive
								end

								if listing.internal_sq_footage
									xml.squareFeet listing.internal_sq_footage
								end

								if !listing.r_beds.nil?
									if listing.r_beds.is_a?(Float) && (listing.r_beds.to_i == listing.r_beds)
										xml.bedrooms listing.r_beds.to_i
									else
										xml.bedrooms listing.r_beds
									end
								elsif !listing.s_beds.nil?
									xml.bedrooms listing.s_beds
								end

								if listing.r_total_room_count
						        	xml.totalrooms listing.r_total_room_count.to_i
						        end
						        if listing.s_total_room_count
						        	xml.totalrooms listing.s_total_room_count.to_i
						        end

								baths = nil
								if !listing.r_baths.nil?
									baths = listing.r_baths
								elsif !listing.s_baths.nil?
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

								pb_description = ""
								if listing.building.landlord
									if !listing.building.landlord.ll_public_description.nil?
										pb_description = listing.building.landlord.ll_public_description
									end
								end
								b_description = ""
								if listing.building
									if !listing.building.description.blank?
										b_description = listing.building.description
									end
								end
								t_description = ""
								if !listing.residential_listing.tenant_description.nil?  && !listing.residential_listing.tenant_description.blank?
									t_description = "Tenant Quote " + listing.residential_listing.tenant_description
								end

								if listing.r_id
									xml.description h raw sanitize t_description + " " + b_description + " " + listing.description + " " + pb_description,
					        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
					      elsif listing.s_id
					        xml.description h raw sanitize listing.public_description,
					        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
								end

								if listing.r_id
									xml.propertyType "rental"
								elsif listing.s_id
									xml.propertyType listing.sales_listing.listing_type
								end
								# xml.propertyType @ptype
								if listing.property_tax
									xml.taxes listing.property_tax
								end
								if listing.common_chargers
									xml.maintenance listing.common_chargers
								end
								# streeteasy has their own approved list of amenities
								# doorman, gym, pool, elevator, garage, parking, balcony, storage, patio, fireplace
								# washerDryer, dishwasher, furnished, pets, other
								if listing.s_id
									#xml.amenities listing.sales_listing.sales_amenities.map(&:name).join(",")
									xml.amenities do
										@other_amenities = []
										listing.sales_listing.sales_amenities.map{|a| a.name}.each do |rm|

											case rm
												when "dishwasher"
													xml.dishwasher
												when "patio"
													xml.patio
												when "pets allowed"
													xml.pets
												when "fireplace"
													xml.fireplace
												else
													@other_amenities << rm
											end
										end
										if !@other_amenities.blank?
											xml.other @other_amenities.join(", ")
										end
									end
								else
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

										pets_allowed = ["case by case",  "cats only", "cats/small dogs", "dogs only", "monthly pet fee" ,
												"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
										if @pet_policies[listing.building_id] && pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
											xml.pets
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

									end
								end # amenities
							end # details

							if !@open_houses[listing.unit_id].blank?
								xml.openHouses do
									@open_houses[listing.unit_id].each do |oh|
										xml.openHouse do
											# must match this format: 2006-11-20 3:30pm
											xml.startsAt oh.day.strftime("%Y-%m-%d") + " " + oh.start_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
											xml.endsAt oh.day.strftime("%Y-%m-%d") + " " + oh.end_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
											if listing.s_id
												if oh.appt_only == true
													xml.apptOnly
												end
											end
											if !listing.s_id
												xml.apptOnly
											end
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
							if !listing.primary_agent_id.nil?
									user = User.find(listing.primary_agent_id)

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

							# if listing.residential_listing.streeteasy_flag == true
				   #            xml.agent id: 114 do
				   #              xml.name "Myspace NYC"
				   #              xml.email "info+streeteasy@myspacenyc.com"
				   #              xml.lead_email "info+streeteasy@myspacenyc.com"
				   #              xml.phone_numbers do
				   #                xml.office "9292748181"
				   #              end
				   #            end
				   #            @primary_agents[listing.unit_id].each do |agent|
							# 		xml.agent id: agent.id do
							# 			xml.name agent.name
							# 			xml.company @company.name
							# 			if @agent_images[agent.id]
							# 				xml.photo url:@agent_images[agent.id].file.url(:large)
							# 			end
							# 		  # xml.url agent.public_url
							# 		xml.email agent.streeteasy_email
							# 		xml.lead_email agent.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main agent.streeteasy_mobile_number
							# 			xml.office agent.office_telephone
							# 			xml.cell agent.streeteasy_mobile_number
							# 			xml.fax agent.office_fax
							# 		end
							# 		end
							# 	end
				   #          end
							# if listing.residential_listing.streeteasy_flag_one == true
							# 	if listing.streeteasy_primary_agent_id
							# 		user = User.find(listing.streeteasy_primary_agent_id)

							# 		xml.agent id: user.id do
							# 			xml.name user.name
							# 			xml.company @company.name
							# 			if user.image
							# 				xml.photo url:user.image.file.url(:large)
							# 			end

							# 		xml.email user.streeteasy_email
							# 		xml.lead_email user.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main user.streeteasy_mobile_number
							# 			xml.office user.office.telephone
							# 			xml.cell user.streeteasy_mobile_number
							# 			xml.fax user.office.fax
							# 		end
							# 	end
							# 	end
							# 	if !listing.primary_agent2_id.nil?
							# 		user = User.find(listing.primary_agent2_id)

							# 		xml.agent id: user.id do
							# 			xml.name user.name
							# 			xml.company @company.name
							# 			if user.image
							# 				xml.photo url:user.image.file.url(:large)
							# 			end

							# 		xml.email user.streeteasy_email
							# 		xml.lead_email user.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main user.streeteasy_mobile_number
							# 			xml.office user.office.telephone
							# 			xml.cell user.streeteasy_mobile_number
							# 			xml.fax user.office.fax
							# 		end
							# 	end
							# 	end
							# end
			            else

			            	if !listing.primary_agent_id.nil?
									user = User.find(listing.primary_agent_id)

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
							# if listing.sales_listing.streeteasy_flag == true
				   #            xml.agent id: 114 do
				   #              xml.name "Myspace NYC"
				   #              xml.email "info+streeteasy@myspacenyc.com"
				   #              xml.lead_email "info+streeteasy@myspacenyc.com"
				   #              xml.phone_numbers do
				   #                xml.office "9292748181"
				   #              end
				   #            end
				   #            @primary_agents[listing.unit_id].each do |agent|
							# 		xml.agent id: agent.id do
							# 			xml.name agent.name
							# 			xml.company @company.name
							# 			if @agent_images[agent.id]
							# 				xml.photo url:@agent_images[agent.id].file.url(:large)
							# 			end
							# 		  # xml.url agent.public_url
							# 		xml.email agent.streeteasy_email
							# 		xml.lead_email agent.streeteasy_email
							# 		xml.phone_numbers do
							# 			xml.main agent.streeteasy_mobile_number
							# 			xml.office agent.office_telephone
							# 			xml.cell agent.streeteasy_mobile_number
							# 			xml.fax agent.office_fax
							# 		end
							# 		end
							# 	end
				   #          end
			            end # end forced
								end
							end

							xml.media do
								if !listing.youtube_video_url.blank?
									xml.video url: listing.youtube_video_url, description: "Take a virtual tour of #{listing.street_number + " " + listing.route}"
								end
								if @bldg_images[listing.building_id]
									@bldg_images[listing.building_id].each do |i|
										xml.photo url:i.file.url(:large), position: i.priority, description:""
									end
								end
								if @images[listing.unit_id]
									@images[listing.unit_id].each do |i|
										if i.floorplan != true
											xml.photo url:i.file.url(:large), position: i.priority, description:""
										end
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
					end	

					# if (listing.residential_listing.roomshare_department == true && (listing.status == "active" || listing.status == "rsonly"))
						
					# 	listing.residential_listing.rooms.where(status: 0).each do |one_room|
					# 			public_url = "https://myspacenyc.com/rooms/rooms-details/?rid=#{listing.id}"
					# 			listing_id = "#{one_room.id}" + "-" + one_room.name.downcase.tr(" ", "-")
					# 			xml.property type: "room", status: "active", id: listing_id, url: public_url do
					# 			xml.location do
					# 				# note we don't want to give out the building number for rentals!
					# 				if	!listing.residential_listing.alt_address.blank?
				 #                  		xml.address listing.residential_listing.alt_address
				 #                  	else
					# 					xml.address listing.street_number + " " + listing.route
					# 				end
					# 				if !listing.streeteasy_unit.nil?
					# 					xml.apartment listing.streeteasy_unit
					# 				else
					# 					xml.apartment listing.building_unit
					# 				end
					# 				xml.city listing.sublocality
					# 				xml.state listing.administrative_area_level_1_short
					# 				xml.zipcode listing.postal_code
					# 				xml.neighborhood listing.neighborhood_name
					# 			end

					# 			xml.details do
					# 				xml.room_name one_room.name
					# 				xml.price one_room.rent

					# 			 	if !listing.has_fee
					# 			 		xml.noFee
					# 			 	end

					# 				if listing.exclusive
					# 					xml.exclusive
					# 				end

					# 				if listing.internal_sq_footage
					# 					xml.squareFeet listing.internal_sq_footage
					# 				end

					# 				if !listing.r_beds.nil?
					# 					if listing.r_beds.is_a?(Float) && (listing.r_beds.to_i == listing.r_beds)
					# 						xml.bedrooms listing.r_beds.to_i
					# 					else
					# 						xml.bedrooms listing.r_beds
					# 					end
					# 				elsif !listing.s_beds.nil?
					# 					xml.bedrooms listing.s_beds
					# 				end

					# 				if listing.r_total_room_count
					# 		        	xml.totalrooms listing.r_total_room_count.to_i
					# 		        end
					# 		        if listing.s_total_room_count
					# 		        	xml.totalrooms listing.s_total_room_count.to_i
					# 		        end

					# 				baths = nil
					# 				if !listing.r_baths.nil?
					# 					baths = listing.r_baths
					# 				elsif !listing.s_baths.nil?
					# 					baths = listing.s_baths
					# 				end

					# 				if baths
					# 					xml.bathrooms baths.floor.to_i
					# 					decimal_idx = baths.to_s.index('.5')
					# 					if !decimal_idx.nil?
					# 						xml.half_baths 1
					# 					end
					# 				end

					# 				xml.availableOn listing.available_by # rentals only

					# 				pb_description = ""
					# 				if listing.building.landlord
					# 					if !listing.building.landlord.ll_public_description.nil?
					# 						pb_description = listing.building.landlord.ll_public_description
					# 					end
					# 				end
					# 				b_description = ""
					# 				if listing.building
					# 					if !listing.building.description.blank?
					# 						b_description = listing.building.description
					# 					end
					# 				end
					# 				t_description = ""
					# 				if !listing.residential_listing.tenant_description.nil?  && !listing.residential_listing.tenant_description.blank?
					# 					t_description = "Tenant Quote " + listing.residential_listing.tenant_description
					# 				end

					# 				if listing.r_id
					# 					xml.description h raw sanitize t_description + " " + b_description + " " + listing.description + " " + pb_description,
					# 	        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
					# 	      elsif listing.s_id
					# 	        xml.description h raw sanitize listing.public_description,
					# 	        		tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
					# 				end

					# 				if listing.r_id
					# 					if listing.residential_listing.roomshare_department == false
					# 						xml.propertyType "rental"
					# 					else
					# 						xml.propertyType "room"
					# 					end
					# 				elsif listing.s_id
					# 					xml.propertyType listing.sales_listing.listing_type
					# 				end
					# 				# xml.propertyType @ptype
					# 				if listing.property_tax
					# 					xml.taxes listing.property_tax
					# 				end
					# 				if listing.common_chargers
					# 					xml.maintenance listing.common_chargers
					# 				end
					# 				# streeteasy has their own approved list of amenities
					# 				# doorman, gym, pool, elevator, garage, parking, balcony, storage, patio, fireplace
					# 				# washerDryer, dishwasher, furnished, pets, other
					# 				if listing.s_id
					# 					#xml.amenities listing.sales_listing.sales_amenities.map(&:name).join(",")
					# 					xml.amenities do
					# 						@other_amenities = []
					# 						listing.sales_listing.sales_amenities.map{|a| a.name}.each do |rm|

					# 							case rm
					# 								when "dishwasher"
					# 									xml.dishwasher
					# 								when "patio"
					# 									xml.patio
					# 								when "pets allowed"
					# 									xml.pets
					# 								when "fireplace"
					# 									xml.fireplace
					# 								else
					# 									@other_amenities << rm
					# 							end
					# 						end
					# 						if !@other_amenities.blank?
					# 							xml.other @other_amenities.join(", ")
					# 						end
					# 					end
					# 				else
					# 					xml.amenities do

					# 						@other_amenities = []
					# 						attribute_found = {}
					# 						if @building_amenities[listing.building_id]
					# 							@building_amenities[listing.building_id].map{|b| b.name}.each do |bm|
					# 								case bm
					# 									when "doorman"
					# 										xml.doorman
					# 									when "gym", "fitness center", "sauna"
					# 										if !attribute_found["gym"]
					# 											attribute_found["gym"] = 1
					# 											xml.gym
					# 										end
					# 									when "pool"
					# 										xml.pool
					# 									when "elevator"
					# 										xml.elevator
					# 									when "garage parking"
					# 										xml.garage
					# 									when "parking", "parking for $200 a month"
					# 										if !attribute_found["parking"]
					# 											attribute_found["parking"] = 1
					# 											xml.parking
					# 										end
					# 									when "balcony"
					# 										xml.balcony
					# 									when "storage"
					# 										xml.storage
					# 									when "courtyard", "shared yard for building"
					# 										if !attribute_found["patio"]
					# 											attribute_found["patio"] = 1
					# 											xml.patio # outdoor space ?
					# 										end
					# 									when "fireplace"
					# 										xml.fireplace
					# 									# when "laundry in building"
					# 									# 	if !attribute_found["washerDryer"]
					# 									# 		attribute_found["washerDryer"] = 1
					# 									# 		xml.washerDryer
					# 									# 	end
					# 									# 	@laundry_included = true
					# 									else
					# 										@other_amenities << bm
					# 								end # case
					# 							end
					# 						end

					# 						pets_allowed = ["case by case",  "cats only", "cats/small dogs", "dogs only", "monthly pet fee" ,
					# 								"pet deposit required", "pets allowed", "pets ok", "pets upon approval", "small pets ok (<30lbs)"]
					# 						if @pet_policies[listing.building_id] && pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
					# 							xml.pets
					# 						end

					# 						if @residential_amenities && @residential_amenities[listing.unit_id]
					# 							@residential_amenities[listing.unit_id].map{|a| a.name}.each do |rm|

					# 								case rm
					# 									when "balcony/terrace"
					# 										xml.balcony
					# 									when "storage", "basement"
					# 										xml.storage
					# 									when "private yard", "shared yard"
					# 										xml.patio # outdoor space ?
					# 									when "washer/dryer hookups", "washer/dryer in unit"
					# 										if !attribute_found["washerDryer"]
					# 											attribute_found["washerDryer"] = 1
					# 											xml.washerDryer
					# 										end
					# 									when "dishwasher"
					# 										xml.dishwasher
					# 									when "furnished"
					# 										xml.furnished
					# 									else
					# 										if !attribute_found[rm]
					# 											attribute_found[rm] = 1
					# 											@other_amenities << rm
					# 										end
					# 								end # case

					# 							end
					# 						end

					# 						if !@other_amenities.blank?
					# 							xml.other @other_amenities.join(", ")
					# 						end

					# 					end
					# 				end # amenities
					# 			end # details

					# 			if !@open_houses[listing.unit_id].blank?
					# 				xml.openHouses do
					# 					@open_houses[listing.unit_id].each do |oh|
					# 						xml.openHouse do
					# 							# must match this format: 2006-11-20 3:30pm
					# 							xml.startsAt oh.day.strftime("%Y-%m-%d") + " " + oh.start_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
					# 							xml.endsAt oh.day.strftime("%Y-%m-%d") + " " + oh.end_time.in_time_zone("Eastern Time (US & Canada)").strftime("%I:%M%p")
					# 							if listing.s_id
					# 								if oh.appt_only == true
					# 									xml.apptOnly
					# 								end
					# 							end
					# 							if !listing.s_id
					# 								xml.apptOnly
					# 							end
					# 						end
					# 					end
					# 				end
					# 			end

					# 			if  !listing.primary_agent_id.blank? || !listing.streeteasy_primary_agent_id.blank?
					# 				xml.agents do
					# 					# On all residential listings, set the company account as the first "agent".
				 #            # This is used for accounting purposes, as Streeteasy charges a fee per ad.
				 #            # if listing.listing_id = 3207478
				 #            # 	abort Unit.where(listing_id: listing.listing_id)[0].residential_listing.inspect
				 #            # end
				 #            if listing.r_id
					# 			#unit = Unit.where(listing_id: listing.listing_id)[0].residential_listing
					# 			#abort listing.residential_listing.inspect
					# 			if !listing.primary_agent_id.nil?
					# 					user = User.find(listing.primary_agent_id)

					# 					xml.agent id: user.id do
					# 						xml.name user.name
					# 						xml.company @company.name
					# 						if user.image
					# 							xml.photo url:user.image.file.url(:large)
					# 						end

					# 					xml.email user.streeteasy_email
					# 					xml.lead_email user.streeteasy_email
					# 					xml.phone_numbers do
					# 						xml.main user.streeteasy_mobile_number
					# 						xml.office user.office.telephone
					# 						xml.cell user.streeteasy_mobile_number
					# 						xml.fax user.office.fax
					# 					end
					# 				end
					# 			end

					# 			# if listing.residential_listing.streeteasy_flag == true
					#    #            xml.agent id: 114 do
					#    #              xml.name "Myspace NYC"
					#    #              xml.email "info+streeteasy@myspacenyc.com"
					#    #              xml.lead_email "info+streeteasy@myspacenyc.com"
					#    #              xml.phone_numbers do
					#    #                xml.office "9292748181"
					#    #              end
					#    #            end
					#    #            @primary_agents[listing.unit_id].each do |agent|
					# 			# 		xml.agent id: agent.id do
					# 			# 			xml.name agent.name
					# 			# 			xml.company @company.name
					# 			# 			if @agent_images[agent.id]
					# 			# 				xml.photo url:@agent_images[agent.id].file.url(:large)
					# 			# 			end
					# 			# 		  # xml.url agent.public_url
					# 			# 		xml.email agent.streeteasy_email
					# 			# 		xml.lead_email agent.streeteasy_email
					# 			# 		xml.phone_numbers do
					# 			# 			xml.main agent.streeteasy_mobile_number
					# 			# 			xml.office agent.office_telephone
					# 			# 			xml.cell agent.streeteasy_mobile_number
					# 			# 			xml.fax agent.office_fax
					# 			# 		end
					# 			# 		end
					# 			# 	end
					#    #          end
					# 			# if listing.residential_listing.streeteasy_flag_one == true
					# 			# 	if listing.streeteasy_primary_agent_id
					# 			# 		user = User.find(listing.streeteasy_primary_agent_id)

					# 			# 		xml.agent id: user.id do
					# 			# 			xml.name user.name
					# 			# 			xml.company @company.name
					# 			# 			if user.image
					# 			# 				xml.photo url:user.image.file.url(:large)
					# 			# 			end

					# 			# 		xml.email user.streeteasy_email
					# 			# 		xml.lead_email user.streeteasy_email
					# 			# 		xml.phone_numbers do
					# 			# 			xml.main user.streeteasy_mobile_number
					# 			# 			xml.office user.office.telephone
					# 			# 			xml.cell user.streeteasy_mobile_number
					# 			# 			xml.fax user.office.fax
					# 			# 		end
					# 			# 	end
					# 			# 	end
					# 			# 	if !listing.primary_agent2_id.nil?
					# 			# 		user = User.find(listing.primary_agent2_id)

					# 			# 		xml.agent id: user.id do
					# 			# 			xml.name user.name
					# 			# 			xml.company @company.name
					# 			# 			if user.image
					# 			# 				xml.photo url:user.image.file.url(:large)
					# 			# 			end

					# 			# 		xml.email user.streeteasy_email
					# 			# 		xml.lead_email user.streeteasy_email
					# 			# 		xml.phone_numbers do
					# 			# 			xml.main user.streeteasy_mobile_number
					# 			# 			xml.office user.office.telephone
					# 			# 			xml.cell user.streeteasy_mobile_number
					# 			# 			xml.fax user.office.fax
					# 			# 		end
					# 			# 	end
					# 			# 	end
					# 			# end
				 #            else

				 #            	if !listing.primary_agent_id.nil?
					# 					user = User.find(listing.primary_agent_id)

					# 					xml.agent id: user.id do
					# 						xml.name user.name
					# 						xml.company @company.name
					# 						if user.image
					# 							xml.photo url:user.image.file.url(:large)
					# 						end

					# 					xml.email user.streeteasy_email
					# 					xml.lead_email user.streeteasy_email
					# 					xml.phone_numbers do
					# 						xml.main user.streeteasy_mobile_number
					# 						xml.office user.office.telephone
					# 						xml.cell user.streeteasy_mobile_number
					# 						xml.fax user.office.fax
					# 					end
					# 				end
					# 			end
					# 			# if listing.sales_listing.streeteasy_flag == true
					#    #            xml.agent id: 114 do
					#    #              xml.name "Myspace NYC"
					#    #              xml.email "info+streeteasy@myspacenyc.com"
					#    #              xml.lead_email "info+streeteasy@myspacenyc.com"
					#    #              xml.phone_numbers do
					#    #                xml.office "9292748181"
					#    #              end
					#    #            end
					#    #            @primary_agents[listing.unit_id].each do |agent|
					# 			# 		xml.agent id: agent.id do
					# 			# 			xml.name agent.name
					# 			# 			xml.company @company.name
					# 			# 			if @agent_images[agent.id]
					# 			# 				xml.photo url:@agent_images[agent.id].file.url(:large)
					# 			# 			end
					# 			# 		  # xml.url agent.public_url
					# 			# 		xml.email agent.streeteasy_email
					# 			# 		xml.lead_email agent.streeteasy_email
					# 			# 		xml.phone_numbers do
					# 			# 			xml.main agent.streeteasy_mobile_number
					# 			# 			xml.office agent.office_telephone
					# 			# 			xml.cell agent.streeteasy_mobile_number
					# 			# 			xml.fax agent.office_fax
					# 			# 		end
					# 			# 		end
					# 			# 	end
					#    #          end
				 #            end # end forced
					# 				end
					# 			end

					# 			xml.media do
					# 				if !listing.youtube_video_url.blank?
					# 					xml.video url: listing.youtube_video_url, description: "Take a virtual tour of #{listing.street_number + " " + listing.route}"
					# 				end
					# 				if @bldg_images[listing.building_id]
					# 					@bldg_images[listing.building_id].each do |i|
					# 						xml.photo url:i.file.url(:large), position: i.priority, description:""
					# 					end
					# 				end
					# 				if @images[listing.unit_id]
					# 					@images[listing.unit_id].each do |i|
					# 						if i.floorplan != true
					# 							xml.photo url:i.file.url(:large), position: i.priority, description:""
					# 						end
					# 					end
					# 				end
					# 				if @images[listing.unit_id]
					# 					@images[listing.unit_id].each do |i|
					# 						if i.floorplan == true
					# 							xml.floorplan url:i.file.url(:large), description:""
					# 						end
					# 					end
					# 				end
					# 			end

					# 		end # property
					# 	end
					# end
				end	
			end # listings.each
		end
	end # properties
end #streeteasy
#end # cache
