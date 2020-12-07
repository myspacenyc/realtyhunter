# todo: before re-enabling caching here, need to figure out how to expire the cache here
# when a building photo is updated. the building photo is displayed before listings photos,
# but adding/removing building photos does not update the listing object.
#cache "streeteasy/#{@listings.ids.join('')}-#{@listings.ids.count}-#{@listings.maximum(:updated_at).to_i}" do

# url looks like <base_url>/syndication/1/streeteasy
xml.instruct! :xml, :version => "1.0"
xml.streeteasy :version => "1.6" do
  xml.properties do

    @listings.each do |listing|

      # NOTE: this is super hacky. We should filter this out before sending
      # to the view.  
      if !@primary_agents[listing.unit_id].blank? &&
            @primary_agents[listing.unit_id][0].name == @company.name
        # skip our generic catch-all account
        next
      end

      # @status = 'active'
      if listing.status == "active"
        @status = "active"
      elsif listing.status == "pending"
        @status = "in-contract"
      # elsif listing.status == "off"
      #   @status == "rented"
      end

      # listing type

      if listing.r_id
        if listing.residential_listing.roomshare_department == false
          @ptype = "rental"
        elsif listing.residential_listing.roomshare_department == true
          @ptype = "room"
        end
        #@ptype = "rental"
      elsif listing.s_id
        @ptype = "sale"
      end

      # Hack: Nestio will not import a listings without a URL defined. Here we set a 'catch-all'
      # value for any listings that don't have a url defined.
      public_url = listing.public_url || 'http://www.myspacenyc.com'
      if listing.residential_listing
        if listing.residential_listing.roomshare_department == false
          if (listing.building.route.split(" ")[0] =~ /\d/).nil? || (listing.building.route.split(" ")[1] =~ /\d/).nil?
            xml.property type: @ptype, status: @status, id: listing.listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  xml.address listing.street_number + " " + listing.route
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      if !listing.streeteasy_primary_agent_id.nil?
                        xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      end
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
          if listing.building.route.split(" ")[0] =~ /\d/ || listing.building.route.split(" ")[1] =~ /\d/
            xml.property type: @ptype, status: @status, id: listing.listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                #abort listing.route.split(" ")[0].to_i.to_s.concat(" " + listing.route.split(" ")[1]).inspect
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  if listing.building.route.split(" ")[0] =~ /\d/
                    xml.address listing.street_number + " " + listing.route.split(" ")[0].to_i.to_s.concat(" " + listing.route.split(" ")[1])
                  end
                  if listing.building.route.split(" ")[1] =~ /\d/
                    xml.address listing.street_number + " " + listing.route.split(" ")[0].concat(" " + listing.route.split(" ")[1].to_i.to_s + " " + listing.route.split(" ")[2])
                  end
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
                if @images[listing.unit_id]
                  @images[listing.unit_id].each do |i|
                    if i.floorplan == true
                      xml.floorplan url:i.file.url(:large), description:""
                    end
                  end
                end
              end

            end # property
            xml.property type: @ptype, status: @status, id: listing.listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  xml.address listing.street_number + " " + listing.route
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
        end
        if listing.residential_listing.roomshare_department == true && listing.status == "active"
          if listing.building.route.split(" ")[0] =~ /\d/ || listing.building.route.split(" ")[1] =~ /\d/
            xml.property type: "rental", status: @status, id: listing.listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  if listing.building.route.split(" ")[0] =~ /\d/
                    xml.address listing.street_number + " " + listing.route.split(" ")[0].to_i.to_s.concat(" " + listing.route.split(" ")[1])
                  end
                  if listing.building.route.split(" ")[1] =~ /\d/
                    xml.address listing.street_number + " " + listing.route.split(" ")[0].concat(" " + listing.route.split(" ")[1].to_i.to_s + " " + listing.route.split(" ")[2])
                  end
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
                if @images[listing.unit_id]
                  @images[listing.unit_id].each do |i|
                    if i.floorplan == true
                      xml.floorplan url:i.file.url(:large), description:""
                    end
                  end
                end
              end

            end # property
            xml.property type: "rental", status: @status, id: listing.listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  xml.address listing.street_number + " " + listing.route
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
                if @images[listing.unit_id]
                  @images[listing.unit_id].each do |i|
                    if i.floorplan == true
                      xml.floorplan url:i.file.url(:large), description:""
                    end
                  end
                end
              end

            end # property
          else
            xml.property type: "rental", status: @status, id: listing.listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  xml.address listing.street_number + " " + listing.route
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
        end
        if (listing.residential_listing.roomshare_department == true && (listing.status == "active" || listing.status == "rsonly"))
          listing.residential_listing.rooms.where(status: 0).each do |one_room|
            public_url = "https://myspacenyc.com/rooms/rooms-details/?rid=#{listing.id}"
            listing_id = "#{one_room.id}" + "-" + one_room.name.downcase.tr(" ", "-")
            xml.property type: @ptype, status: "active", id: listing_id, url: public_url do
              xml.location do
                # note we don't want to give out the building number for rentals!
                if !listing.residential_listing.alt_address.blank?
                  xml.address listing.residential_listing.alt_address
                else
                  xml.address listing.street_number + " " + listing.route
                end
                if !listing.streeteasy_unit.blank?
                  xml.apartment listing.streeteasy_unit
                else
                  xml.apartment listing.building_unit
                end
                xml.city listing.sublocality
                xml.state listing.administrative_area_level_1_short
                if !listing.building.dotsignal_code.nil?
                  listing.postal_code = listing.building.dotsignal_code
                end
                xml.zipcode listing.postal_code
                xml.neighborhood listing.neighborhood_name
              end

              xml.details do
                xml.room_name one_room.name
                xml.price one_room.rent
                
                if listing.residential_listing
                  if listing.residential_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end

                if listing.sales_listing
                  if listing.sales_listing.tenant_occupied == true
                    xml.tenant_occupied true
                  else
                    xml.tenant_occupied false
                  end
                end
                
                #xml.price listing.rent

                if !listing.has_fee
                  xml.noFee
                end

                if listing.exclusive
                  xml.exclusive
                end

                if listing.building.landlord
                  xml.ll_code listing.building.landlord.code
                end

                if !listing.r_beds.nil?
                  xml.bedrooms listing.r_beds.to_i
                elsif !listing.s_beds.nil?
                  xml.bedrooms listing.s_beds.to_i
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

                if !listing.lease_start.nil?
                  xml.lease_term_min listing.lease_start
                end

                if !listing.lease_end.nil?
                  xml.lease_term_max listing.lease_end
                end

                if listing.residential_listing
                  if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
                    xml.streeteasy true
                    #abort listing.residential_listing.audits.inspect
                    if listing.residential_listing.streeteasy_flag == true
                      xml.streeteasy_user "MySpaceNYC"
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag"].class == Array
                            if audit.audited_changes["streeteasy_flag"][1] == true
                              if listing.residential_listing.streeteasy_flag == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                     end
                    else
                      xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                      if listing.residential_listing.unit.audits
                        listing.residential_listing.audits.each do |audit|
                          if audit.audited_changes["streeteasy_flag_one"].class == Array
                            if audit.audited_changes["streeteasy_flag_one"][1] == true
                              if listing.residential_listing.streeteasy_flag_one == true
                                @disp_se_date = audit.created_at
                                @disp_se_date
                              end
                            end
                          end
                        end
                        if listing.residential_listing.streeteasy_flag_one == true
                          if !@disp_se_date.nil?
                            xml.streeteasy_date time_ago_in_words(@disp_se_date)
                          end
                        end
                      end
                    end
                  else
                    xml.streeteasy false
                  end
                end
                if !listing.building.point_of_contact.nil?
                  xml.point_of_contact User.find(listing.building.point_of_contact).name
                end

                if listing.r_id
                  xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                elsif listing.s_id
                  xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                      tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
                end

                if listing.r_id
                  xml.propertyType "rental"
                elsif listing.s_id
                  xml.propertyType "house"
                end

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
                        # when "laundry in building"
                        #   if !attribute_found["washerDryer"]
                        #     attribute_found["washerDryer"] = 1
                        #     xml.washerDryer
                        #   end
                        #   @laundry_included = true
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

                  if @pet_policies[listing.building_id]
                    pets_allowed = [
                      "monthly pet fee",
                      "pet deposit required",
                      "pets allowed",
                      "pets ok",
                      "pets upon approval"
                    ]
                    if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                      xml.pets "Pets Allowed"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                      xml.pets "No Pets"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                      xml.pets "Case By Case"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                      xml.pets "Cats Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                      xml.pets "Dogs Only"
                    elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                        @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                      xml.pets "Small Pets"
                    end
                  end

                end # amenities
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

              if !listing.r_note.nil? && !listing.r_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.r_note.strip
                end
              elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
                xml.internal do
                  xml.private_notes listing.s_note.strip
                end
              end

              if !@primary_agents[listing.unit_id].blank?
                xml.agents do
                  # On all residential listings, set the company account as the first "agent".
                  # This is used for accounting purposes, as Streeteasy charges a fee per ad.
                  if listing.r_id
                    xml.agent id: 114 do
                      xml.name "Myspace NYC"
                      xml.email "info@myspacenyc.com"
                      xml.lead_email "info@myspacenyc.com"
                      xml.phone_numbers do
                        xml.office "9292748181"
                      end
                    end
                  end # end forced
                  @primary_agents[listing.unit_id].each do |agent|
                    xml.agent id: agent.id do
                      xml.name agent.name
                      xml.company @company.name
                      if @agent_images[agent.id]
                        #xml.photo url:@agent_images[agent.id].file.url(:large)
                      end
                      # xml.url agent.public_url
                      xml.email agent.email
                      xml.lead_email agent.email
                      xml.phone_numbers do
                        xml.main agent.mobile_phone_number
                        xml.office agent.office_telephone
                        xml.cell agent.mobile_phone_number
                        xml.fax agent.office_fax
                      end
                    end
                  end
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
        end
      else
        xml.property type: @ptype, status: @status, id: listing.listing_id, url: public_url do
        xml.location do
          # note we don't want to give out the building number for rentals!
          xml.address listing.street_number + " " + listing.route
          xml.apartment listing.building_unit
          xml.city listing.sublocality
          xml.state listing.administrative_area_level_1_short
          if !listing.building.dotsignal_code.nil?
            listing.postal_code = listing.building.dotsignal_code
          end
          xml.zipcode listing.postal_code
          xml.neighborhood listing.neighborhood_name
        end

        xml.details do
          
          if listing.residential_listing
            if listing.residential_listing.tenant_occupied == true
              xml.tenant_occupied true
            else
              xml.tenant_occupied false
            end
          end

          if listing.sales_listing
            if listing.sales_listing.tenant_occupied == true
              xml.tenant_occupied true
            else
              xml.tenant_occupied false
            end
          end
          
          xml.price listing.rent

          if !listing.has_fee
            xml.noFee
          end

          if listing.exclusive
            xml.exclusive
          end

          if listing.building.landlord
            xml.ll_code listing.building.landlord.code
          end

          if !listing.r_beds.nil?
            xml.bedrooms listing.r_beds.to_i
          elsif !listing.s_beds.nil?
            xml.bedrooms listing.s_beds.to_i
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

          if !listing.lease_start.nil?
            xml.lease_term_min listing.lease_start
          end

          if !listing.lease_end.nil?
            xml.lease_term_max listing.lease_end
          end

          if listing.residential_listing
            if listing.residential_listing.streeteasy_flag == true || listing.residential_listing.streeteasy_flag_one == true
              xml.streeteasy true
              #abort listing.residential_listing.audits.inspect
              if listing.residential_listing.streeteasy_flag == true
                xml.streeteasy_user "MySpaceNYC"
                if listing.residential_listing.unit.audits
                  listing.residential_listing.audits.each do |audit|
                    if audit.audited_changes["streeteasy_flag"].class == Array
                      if audit.audited_changes["streeteasy_flag"][1] == true
                        if listing.residential_listing.streeteasy_flag == true
                          @disp_se_date = audit.created_at
                          @disp_se_date
                        end
                      end
                    end
                  end
                  if listing.residential_listing.streeteasy_flag == true
                    if !@disp_se_date.nil?
                      xml.streeteasy_date time_ago_in_words(@disp_se_date)
                    end
                  end
               end
              else
                xml.streeteasy_user User.find(listing.streeteasy_primary_agent_id).name
                if listing.residential_listing.unit.audits
                  listing.residential_listing.audits.each do |audit|
                    if audit.audited_changes["streeteasy_flag_one"].class == Array
                      if audit.audited_changes["streeteasy_flag_one"][1] == true
                        if listing.residential_listing.streeteasy_flag_one == true
                          @disp_se_date = audit.created_at
                          @disp_se_date
                        end
                      end
                    end
                  end
                  if listing.residential_listing.streeteasy_flag_one == true
                    if !@disp_se_date.nil?
                      xml.streeteasy_date time_ago_in_words(@disp_se_date)
                    end
                  end
                end
              end
            else
              xml.streeteasy false
            end
          end
          if !listing.building.point_of_contact.nil?
            xml.point_of_contact User.find(listing.building.point_of_contact).name
          end

          if listing.r_id
            xml.description h raw sanitize listing.description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
          elsif listing.s_id
            xml.description h raw sanitize listing.public_description + ' MyspaceNYCListingID: ' + listing.listing_id.to_s,
                tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
          end

          if listing.r_id
            xml.propertyType "rental"
          elsif listing.s_id
            xml.propertyType "house"
          end

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
                  # when "laundry in building"
                  #   if !attribute_found["washerDryer"]
                  #     attribute_found["washerDryer"] = 1
                  #     xml.washerDryer
                  #   end
                  #   @laundry_included = true
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

            if @pet_policies[listing.building_id]
              pets_allowed = [
                "monthly pet fee",
                "pet deposit required",
                "pets allowed",
                "pets ok",
                "pets upon approval"
              ]
              if pets_allowed.include?(@pet_policies[listing.building_id][0].pet_policy_name)
                xml.pets "Pets Allowed"
              elsif @pet_policies[listing.building_id][0].pet_policy_name == 'no pets'
                xml.pets "No Pets"
              elsif @pet_policies[listing.building_id][0].pet_policy_name == 'case by case'
                xml.pets "Case By Case"
              elsif @pet_policies[listing.building_id][0].pet_policy_name == 'cats only'
                xml.pets "Cats Only"
              elsif @pet_policies[listing.building_id][0].pet_policy_name == 'dogs only'
                xml.pets "Dogs Only"
              elsif @pet_policies[listing.building_id][0].pet_policy_name == 'small pets ok (<30lbs)' ||
                  @pet_policies[listing.building_id][0].pet_policy_name == 'cats/small dogs'
                xml.pets "Small Pets"
              end
            end

          end # amenities
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

        if !listing.r_note.nil? && !listing.r_note.strip.empty?
          xml.internal do
            xml.private_notes listing.r_note.strip
          end
        elsif !listing.s_note.nil? && !listing.s_note.strip.empty?
          xml.internal do
            xml.private_notes listing.s_note.strip
          end
        end

        if !@primary_agents[listing.unit_id].blank?
          xml.agents do
            # On all residential listings, set the company account as the first "agent".
            # This is used for accounting purposes, as Streeteasy charges a fee per ad.
            if listing.r_id
              xml.agent id: 114 do
                xml.name "Myspace NYC"
                xml.email "info@myspacenyc.com"
                xml.lead_email "info@myspacenyc.com"
                xml.phone_numbers do
                  xml.office "9292748181"
                end
              end
            end # end forced
            @primary_agents[listing.unit_id].each do |agent|
              xml.agent id: agent.id do
                xml.name agent.name
                xml.company @company.name
                if @agent_images[agent.id]
                  #xml.photo url:@agent_images[agent.id].file.url(:large)
                end
                # xml.url agent.public_url
                xml.email agent.email
                xml.lead_email agent.email
                xml.phone_numbers do
                  xml.main agent.mobile_phone_number
                  xml.office agent.office_telephone
                  xml.cell agent.mobile_phone_number
                  xml.fax agent.office_fax
                end
              end
            end
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
    end # listings.each
  end # properties
end #streeteasy
#end # cache


# # This feed is based largely off the Streeteasy feed spec, but augmented with specific fields
# # that only Nestio uses. Please reference their feed documentation:
# # https://drive.google.com/open?id=0B_EU2U2294snZE9ZQXFxclFxMzA

# # url looks like <base_url>/syndication/1/streeteasy
# xml.instruct! :xml, :version => "1.0"
# xml.streeteasy :version => "1.6" do
#   xml.properties do

#     @listings.each do |listing|

#       # NOTE: this is super hacky. We should filter this out before sending
#       # to the view.
#       if !@primary_agents[listing.unit_id].blank? &&
#             @primary_agents[listing.unit_id][0].name == @company.name
#         # skip our generic catch-all account
#         next
#       end

#       xml.property do# type: @ptype, status: @status, id: listing.listing_id, url: listing.public_url do
#         if listing.status == "active"
#           xml.status "active"
#         elsif listing.status == "pending"
#           xml.status "in-contract"
#         else
#           # we leave this here for completion. as of right now, this is never used.
#           xml.status "rented"
#         end

#         xml.tag! 'rental-terms' do
#           xml.tag! 'rental-broker-fee', listing.has_fee ? 'Yes' : 'No'
#           if !listing.lease_start.nil?
#             xml.tag! 'lease-min-length-months', listing.lease_start
#           end
#           if !listing.lease_end.nil?
#             xml.tag! 'lease-min-length-months', listing.lease_end
#           end
#         end

#         xml.location do
#           xml.tag! 'unit-number', listing.building_unit
#           xml.tag! 'street-address', listing.street_number + " " + listing.route
#           xml.tag! 'city-name', listing.sublocality
#           xml.tag! 'state-code', listing.administrative_area_level_1_short
#           xml.zipcode listing.postal_code
#         end

#         xml.details do
#           if !listing.has_fee
#             xml.tag! 'commission-type', 'owner pays'
#           end

#           if listing.available_by
#             xml.tag! 'date-available', listing.available_by.strftime("%Y-%m-%d") # rentals only
#           end

#           if listing.r_id && !listing.description.empty?
#             xml.description h raw sanitize listing.description,
#                 tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
#           elsif listing.s_id && !listing.public_description.empty?
#             xml.description h raw sanitize listing.public_description,
#                 tags: %w(h1 h2 h3 h4 h5 h6 p i b strong em a ol ul li q blockquote font span br div)
#           end

#           # TODO
#           if listing.exclusive
#             xml.tag! 'exclusive-type', 'exclusive'
#           end

#           if !listing.floor.nil?
#             xml.tag! 'floor-of-unit', listing.floor
#           end

#           if !listing.r_beds.nil?
#             xml.tag! 'num-bedrooms', listing.r_beds.to_i
#           elsif !listing.s_beds.nil?
#             xml.tag! 'num-bedrooms', listing.s_beds.to_i
#           end

#           baths = nil
#           if listing.r_baths
#             baths = listing.r_baths
#           elsif listing.s_baths
#             baths = listing.s_baths
#           end

#           xml.tag! 'num-bathrooms', baths

#           if listing.r_tenant_occupied
#             xml.tag! 'occupancy-status', 'occupied'
#           elsif listing.s_tenant_occupied
#             xml.tag! 'occupancy-status', 'occupied'
#           else
#             xml.tag! 'occupancy-status', 'vacant'
#           end

#           # TODO: our output needs to be sanitized here
#           if @pet_policies[listing.building_id] && @pet_policies[listing.building_id][0].pet_policy_name
#             policy = @pet_policies[listing.building_id][0].pet_policy_name


#             if policy == 'pets allowed'
#               xml.tag! 'pets-policy', 'pets ok'
#             elsif policy == 'no pets'
#               xml.tag! 'no pets'
#             elsif policy == 'small pets ok (<30 lbs)' || policy == 'cats/small dogs'
#               xml.tag! 'small pets'
#             elsif policy == 'cats only'
#               xml.tag! 'pets-policy', policy
#             elsif policy == 'dogs only'
#               xml.tag! 'pets-policy', policy
#             else
#               xml.tag! 'pets-policy', 'case by case'
#             end

#           end

#           xml.tag! 'property-type', "apartment"

#           xml.tag! 'provider-listingid', listing.listing_id

#           xml.price listing.rent

#           if listing.r_total_room_count
#             xml.tag! 'room-count', listing.r_total_room_count.to_i
#           end
#         end #details

#         if @bldg_images[listing.building_id]
#           xml.pictures do
#             @bldg_images[listing.building_id].each do |i|
#               xml.picture do
#                 xml.tag! 'picture-url', i.file.url(:large)
#               end
#             end
#           end
#         end
#         if @images[listing.unit_id]
#           xml.pictures do
#             @images[listing.unit_id].each do |i|
#               xml.picture do
#                 xml.tag! 'picture-url', i.file.url(:large)
#               end
#             end
#           end
#         end

#         if !@primary_agents[listing.unit_id].blank?
#           xml.agents do
#             @primary_agents[listing.unit_id].each do |agent|
#               xml.agent do
#                 xml.tag! 'agent-name', agent.name
#                 xml.tag! 'agent-email', agent.email
#                 xml.tag! 'agent-phone', agent.mobile_phone_number
#               end
#             end
#           end
#         end # agents

#         if !@open_houses[listing.unit_id].blank?
#           xml.tag! 'open-homes' do
#             @open_houses[listing.unit_id].each do |oh|
#               xml.tag! 'open-home' do
#                 xml.tag! 'start-time', oh.start_time.strftime("%H:%M")
#                 xml.tag! 'end-time', oh.end_time.strftime("%H:%M")
#                 xml.date oh.day.strftime("%Y-%m-%d")
#                 xml.details do
#                   xml.tag! 'open-house-appointment-only', true
#                 end
#               end
#             end
#           end
#         end

#         # streeteasy has their own approved list of amenities
#         # doorman, gym, pool, elevator, garage, parking, balcony, storage, patio, fireplace
#         # washerDryer, dishwasher, furnished, pets, other

#         @other_amenities = []
#         attribute_found = {}

#         xml.tag! 'detailed-characteristics' do
#           if @residential_amenities && @residential_amenities[listing.unit_id] &&
#               @residential_amenities[listing.unit_id].length > 0
#             xml.tag! 'other-amenities' do
#               @residential_amenities[listing.unit_id].map{|a| a.name}.each do |amenity|
#                 blacklisted_amenities = ['diswasher', 'furnished', 'washer/dryer hookups']
#                 if !amenity.include? amenity
#                   xml.tag! 'other-amenity', amenity
#                 end
#               end
#             end
#           end

#           if @building_amenities[listing.building_id]
#             @building_amenities[listing.building_id].map{|b| b.name}.each do |bm|
#               case bm
#                 when "laundry in building"
#                   if !attribute_found["washerDryer"]
#                     attribute_found["washerDryer"] = 1
#                     xml.tag! 'building-has-laundry', xml.washerDryer ? 'Yes' : 'No'
#                   end
#                   @laundry_included = true
#                 when "balcony"
#                   xml.tag! 'has-balcony', xml.balcony
#                 when "doorman"
#                   xml.tag! 'building-has-doorman', xml.doorman ? 'Yes' : 'No'
#                 when "elevator"
#                   xml.tag! 'building-has-elevator', xml.elevator ? 'Yes' : 'No'
#                 when "gym", "fitness center", "sauna"
#                   if !attribute_found["gym"]
#                     attribute_found["gym"] = 1
#                     xml.tag! 'building-has-fitness-center', 'Yes'
#                   end
#                 else
#                   @other_amenities << bm
#                 end
#               end # case
#             end
#             if @other_amenities.length > 0
#               xml.tag! 'building-other-amenities' do
#                 @other_amenities.each do |amenity|
#                   xml.tag! 'building-other-amenity', amenity
#                 end
#               end # building-other-amenities
#             end # other_amenities
#           end

#       end # property
#     end # listings.each
#   end # properties
# end #streeteasy
# #end # cache
