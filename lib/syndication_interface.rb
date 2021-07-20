# In order for a listing to be syndicated, it must match the criteria outlined here:
# https://docs.google.com/spreadsheets/d/1JAoiYlU9xIsAiE5O3FbwMNOk5GpxXuYrF8i6WyH5r4E/edit?usp=sharing
#
# Additionally, we give our staff the option of turning a listing 'off'. Sometimes, we may want to
# prevent a listing from syndicating temporarily, so it is important to have this on/off ability.

module SyndicationInterface

	def is_true?(string)
	  ActiveModel::Type::Boolean.new.cast(string)
	end

	# search these conditions
	# - must be active
	# - must belong to this company
	# - must be exclusive OR no-fee (though we choose to hide anything unless it's exclusive...)
	# - must have at least 1 listing agent assigned
	def naked_apts_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		search_params[:has_fee_exclusive] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:has_naked_apartment] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	# search these conditions
	# - must be active
	# - must belong to this company
	# - must be exclusive
	# - must have at least 1 listing agent assigned
	# - must have a description
	def streeteasy_listings(company_id, search_params)
		# In order for streeteasy to accept a listing, the listing must have a primary agent assigned, a
		# description, and must be marked as 'exclusive'.

		# Additionally, sometimes our staff will temporarily mark a listing as not ready for
		# syndication. If the "streeteasy flag" is not set here, we prevent the data from going out.
		search_params[:has_primary_agent] = 1
		search_params[:exclusive] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:must_have_description] = 1
		search_params[:must_have_status_inbetween] = 1
		search_params[:must_have_streeteasy_flag] = 1
		# search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def zumper_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:push_to_zumper_active] = 1
		search_params[:must_have_status_for_zumper] = 1
		#search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def zumper_backup_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:push_to_zumper_active] = 1
		search_params[:must_have_status_for_zumper] = 1
		#search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def test_watermark_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:push_to_zumper_active] = 1
		search_params[:must_have_status_for_zumper] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def external_feed_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:push_to_zumper_active] = 1
		search_params[:must_have_status_for_zumper] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def external_feed_no_rooms_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:push_to_zumper_active] = 1
		search_params[:must_have_status_for_zumper] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def renthop_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:must_have_status_for_zumper] = 1
		search_params[:renthop_active] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def rhexport_listings(company_id, search_params)
		search_params[:must_have_status_selected] = 1
		pull_data(company_id, search_params)
	end

	def apartment_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		search_params[:exclusive] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:must_have_description] = 1
		# search_params[:must_have_apartment] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	# search these conditions
	# - must be active
	# - must belong to this company
	# - must have at least 1 listing agent assigned
	def trulia_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		search_params[:exclusive] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:must_have_description] = 1
		search_params[:must_have_streeteasy_flag] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def zillow_listings(company_id, search_params)
		search_params[:has_primary_agent] = 1
		search_params[:exclusive] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:must_have_description] = 1
		search_params[:must_have_streeteasy_flag] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	# The nestio listing is an identical copy of our streeteasy feed, with some very minor changes
	# to accomodate Nestio's requirements.
	def nestio_listings(company_id, search_params)
		search_params[:is_nestio] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def hotpad_listings(company_id, search_params)
		search_params[:is_hotpad] = 1
		# search_params[:is_hide_on_website] = 1
		search_params[:is_having_description] = 1
		search_params[:has_hide_from_agent] = 1
		pull_data(company_id, search_params)
	end

	def rooms_listings(company_id, search_params)
		search_params[:is_rooms] = 1
		search_params[:has_hide_from_agent] = 1
		#search_params[:is_having_description] = 1
		pull_data(company_id, search_params)
	end

	def dotsignal_listings(company_id, search_params)
		search_params[:is_dotsignal] = 1
		# search_params[:is_hide_on_website] = 1
		pull_data(company_id, search_params)
	end

	def pull_data(company_id, search_params)
		listings = Unit.joins('left join residential_listings on units.id = residential_listings.unit_id
left join sales_listings on units.id = sales_listings.unit_id')
		# Notes:
		# - Left join on the landlords because sales listings do not have a landlord defined.
		# - Since we are joining of the base Unit table, make sure no commerical listings are included.
		 #  We want to only include units that are sales or residential listings.
		listings = listings.joins([building: :company])
			.joins('left join neighborhoods on neighborhoods.id = buildings.neighborhood_id')
			.joins('left join landlords on landlords.id = buildings.landlord_id')
			.where('units.archived = false')
			.where('residential_listings.id IS NOT NULL OR sales_listings.id IS NOT NULL')
			.where('companies.id = ?', company_id)

		# Nestio is still viewed as another "internal system". We send them our data, but we treat this
		# as more of different "frontend" for our listings. Ignore the syndication status flag in their case.
		if is_true?(search_params[:is_nestio])
			listings = listings.where('units.status IN (?)',
					[Unit.statuses["active"], Unit.statuses["pending"]])
		else
			listings = listings.where('units.status IN (?) OR units.syndication_status = ?',
					[Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["deal_pending"], Unit.statuses["contract_out"], Unit.statuses["on_market"], Unit.statuses["offer_submitted"], Unit.statuses["in_escrow"]],
					Unit.syndication_statuses['Force syndicate'])
				.where('units.syndication_status IN (?)', [
					Unit.syndication_statuses['Syndicate if matches criteria'],
					Unit.syndication_statuses['Force syndicate']
				])
		end

		if is_true?(search_params[:is_hotpad])
			#abort listings.where("residential_listings.roomshare_department = TRUE").count.inspect
			#listings = listings.where('units.status IN (?) OR (residential_listings.room_syndication = TRUE AND units.status = 3)',
					#[Unit.statuses["active"], Unit.statuses["pending"]])
			listings = listings.where("residential_listings.roomshare_department = TRUE AND residential_listings.room_syndication = TRUE")
		else
			listings = listings.where('units.status IN (?) OR units.syndication_status = ?',
					[Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["rsonly"], Unit.statuses["deal_pending"], Unit.statuses["contract_out"], Unit.statuses["on_market"], Unit.statuses["offer_submitted"], Unit.statuses["in_escrow"]],
					Unit.syndication_statuses['Force syndicate'])
				.where('units.syndication_status IN (?)', [
					Unit.syndication_statuses['Syndicate if matches criteria'],
					Unit.syndication_statuses['Force syndicate']
				])
		end

		if is_true?(search_params[:is_having_description])
			listings = listings.where("residential_listings.rooms_description <> '' ")
		end

		if is_true?(search_params[:has_hide_from_agent])
			listings = listings.where('units.hide_from_agent =?', false)
		end

		if is_true?(search_params[:is_rooms])
			#abort listings.where("residential_listings.roomshare_department = TRUE").count.inspect
			#listings = listings.where('units.status IN (?) OR (residential_listings.room_syndication = TRUE AND units.status = 3)',
					#[Unit.statuses["active"], Unit.statuses["pending"]])
			listings = listings.where("residential_listings.roomshare_department = TRUE AND units.status IN (?)", [0, 3])
		else
			listings = listings.where('units.status IN (?) OR units.syndication_status = ?',
					[Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["deal_pending"], Unit.statuses["contract_out"], Unit.statuses["on_market"], Unit.statuses["offer_submitted"], Unit.statuses["in_escrow"]],
					Unit.syndication_statuses['Force syndicate'])
				.where('units.syndication_status IN (?)', [
					Unit.syndication_statuses['Syndicate if matches criteria'],
					Unit.syndication_statuses['Force syndicate']
				])
		end

		if is_true?(search_params[:must_have_aparment])
			listings = listings.where('units.status =?', Unit.statuses["active"])
		else
			listings = listings.where('units.status IN (?) OR units.syndication_status = ?',
					[Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["contract_out"], Unit.statuses["deal_pending"], Unit.statuses["on_market"], Unit.statuses["offer_submitted"], Unit.statuses["in_escrow"]], Unit.syndication_statuses['Force syndicate'])
				.where('units.syndication_status IN (?)', [
					Unit.syndication_statuses['Syndicate if matches criteria'],
					Unit.syndication_statuses['Force syndicate']
				])
		end

		#feed url for dotsignal similar as nestio only url change. feed similar to nestio
		if is_true?(search_params[:is_dotsignal])
			listings = listings.where('units.status IN (?)',
					[Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["rsonly"]])
		else
			listings = listings.where('units.status IN (?) OR units.syndication_status = ?',
					[Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["deal_pending"], Unit.statuses["contract_out"], Unit.statuses["on_market"], Unit.statuses["offer_submitted"], Unit.statuses["in_escrow"]],
					Unit.syndication_statuses['Force syndicate'])
				.where('units.syndication_status IN (?)', [
					Unit.syndication_statuses['Syndicate if matches criteria'],
					Unit.syndication_statuses['Force syndicate']
				])
		end


		# if is_true?(search_params[:is_hide_on_website])
		# 	listings = listings.where('units.hide_on_website =?', false)
		# end

		if is_true?(search_params[:has_naked_apartment])
			listings = listings.where('residential_listings.naked_apartment = TRUE')
		end

		if is_true?(search_params[:must_have_status_inbetween])
			listings = listings.where('units.status IN (?)', [Unit.statuses["active"], Unit.statuses["pending"], Unit.statuses["contract_out"], Unit.statuses["on_market"], Unit.statuses["offer_submitted"], Unit.statuses["in_escrow"], Unit.statuses["deal_pending"]])
		end

		if is_true?(search_params[:must_have_status_selected])
			listings = listings.where('units.status IN (?)', [Unit.statuses["active"]])
		end

		if is_true?(search_params[:push_to_zumper_active])
			#listings = listings.where('buildings.push_to_zumper =?', true)
		end

		if is_true?(search_params[:renthop_active])
			listings = listings.where('residential_listings.renthop =?', true)
		end

		if is_true?(search_params[:must_have_status_for_zumper])
			listings = listings.where('units.status IN (?) OR buildings.push_to_zumper =?', [Unit.statuses["active"], Unit.statuses["rsonly"], Unit.statuses["deal_pending"]], true)
		end

		if is_true?(search_params[:has_primary_agent])
			listings = listings.where('units.primary_agent_id > 0 OR units.streeteasy_primary_agent_id > 0')
		end

		# if is_true?(search_params[:room_syndication])
		# 	listings = listings.where("residential_listings.room_syndication = TRUE")
		# end

		# naked requires all no-fee listings to be exposed
		# so we have to filter out the non-exclusive ones on our end
		if is_true?(search_params[:has_fee_exclusive])
			listings = listings.where(
					'residential_listings.has_fee = TRUE OR (residential_listings.has_fee = FALSE AND units.exclusive = TRUE)')
		end

		if is_true?(search_params[:exclusive])
			listings = listings.where('units.exclusive = TRUE')
		end

		if is_true?(search_params[:must_have_description])
			listings = listings.where(
					"residential_listings.description <> '' OR sales_listings.public_description <> '' ")
		end

    # Make sure our staff has approved this listing for syndication to Streeteasy/Nestio.
    # WARNING: DO NOT TURN THIS OFF without consulting the owner of Myspace. Streeteasy
    # has instituted a new policy where they are charging $3 per day, per ad that is
    # syndicated to them. Without this flag in place, we may potentially send them hundreds of
    # listings and incur large fees.
		if is_true?(search_params[:must_have_streeteasy_flag])
      listings = listings.where("residential_listings.streeteasy_flag = TRUE or residential_listings.streeteasy_flag_one = TRUE or
          sales_listings.streeteasy_flag = TRUE")
		end

		listings = listings
			.select('units.id', 'units.building_unit', 'units.status', 'units.available_by',
			'units.listing_id', 'units.updated_at', 'units.rent', 'units.gross_price', 'units.streeteasy_unit' ,
			'units.streeteasy_listing_email', 'units.streeteasy_listing_number', 'units.has_stock_photos',
			'buildings.id as building_id', 'buildings.push_to_zumper',
			'buildings.administrative_area_level_2_short',
			'buildings.administrative_area_level_1_short',
			'buildings.sublocality','buildings.point_of_contact',
			'buildings.street_number', 'buildings.route',
			'buildings.postal_code', 'buildings.dotsignal_code',
			'buildings.lat',
			'buildings.lng',
			'landlords.code', 'landlords.ll_public_description', 'landlords.ll_importance',
			'neighborhoods.name as neighborhood_name',
			'neighborhoods.borough as neighborhood_borough',
			'residential_listings.id AS r_id',
			'residential_listings.notes AS r_note','residential_listings.renthop',
			'residential_listings.lease_start', 'residential_listings.lease_end','residential_listings.dimensions',
			'residential_listings.has_fee', 'residential_listings.beds as r_beds', 'residential_listings.alt_address',
			'residential_listings.baths as r_baths', 'residential_listings.description', 'residential_listings.rooms_description',
			'residential_listings.total_room_count as r_total_room_count', 'residential_listings.rs_only_description',
			'residential_listings.floor', 'residential_listings.room_syndication', 'residential_listings.watermark_in_use',
			'residential_listings.tenant_occupied as r_tenant_occupied', 'residential_listings.op_fee_percentage', 'residential_listings.youtube_video_url',
			'residential_listings.tp_fee_percentage', 'residential_listings.watermark', 'residential_listings.tenant_description',
			'residential_listings.streeteasy_flag', 'residential_listings.streeteasy_flag_one',
			'residential_listings.naked_apartment', 'residential_listings.roomfill', 'residential_listings.partial_move_in',
			'residential_listings.youtube_video_url', 'residential_listings.tour_3d', 'residential_listings.private_youtube_url',
			'sales_listings.id AS s_id',
			'sales_listings.beds as s_beds',
			'sales_listings.baths as s_baths',
			'sales_listings.internal_notes as s_note',
			'sales_listings.public_description',
			'sales_listings.tenant_occupied as s_tenant_occupied',
			'sales_listings.total_room_count as s_total_room_count', 'sales_listings.property_tax',
			'sales_listings.internal_sq_footage', 'sales_listings.common_chargers',
			'units.id as unit_id',
			'units.primary_agent_id','units.access_info',
			'units.primary_agent2_id','units.featured', 'units.hide_from_agent',
			'units.streeteasy_primary_agent_id','units.maths_free',
			'units.public_url', 'units.primary_agent_for_rs',
			'units.exclusive')

		# puts "\n\n\n****** #{listings.length}"
		listings.uniq
	end
end
