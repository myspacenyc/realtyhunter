Rails.application.routes.draw do

  mount Ckeditor::Engine => '/ckeditor'
  mount Bootsy::Engine => '/bootsy', as: 'bootsy'
  resources :images
  #get 'static_pages/help'
  #get 'static_pages/home'

  get 'signup'  => 'users#new'
  get 'sessions/new'
  get 'login' => 'sessions#new'
  post 'login' => 'sessions#create'
  delete 'logout' => 'sessions#destroy'
  get 'user_home' => 'sessions#user_home'

  root :to => 'sessions#new'

  get "all_active_users" => "users#all_active_users", as: :all_active_users
  resources :users, except: 'new' do
    get :autocomplete_user_name, :on => :collection
    collection do
      get 'update_offices'
      get 'filter'
      # these are for when someone in the company adds a new employee:
      get 'admin_new'
      post 'admin_create'
    end
    member do
      patch 'unarchive'
      delete 'destroy_image'
      post 'upload_image'
      get 'coworkers'
      get 'subordinates'
      post 'admin_approve'
      post 'admin_unapprove'
      post 'admin_kick'
      patch 'new_auth_token'
      get 'filter_listings'
    end
  end

  resources :account_activations, only: [:edit]
  resources :account_approvals,   only: [:edit]
  resources :added_by_admins,     only: [:edit, :update]
  resources :password_resets,     only: [:new, :create, :edit, :update]

  get 'edit_faq_company_policy' => "companies#edit_faq_company_policy", as: :edit_faq_company_policy
  get 'faq_company_policy' => "companies#faq_company_policy", as: :faq_company_policy
  post 'update_faq_company_policy' => "companies#update_faq_company_policy", as: :update_faq_company_policy
  resources :companies do
    collection do
      get 'filter'
    end
    member do
      get 'managers'
      get 'employees'
      delete 'destroy_image'
    end

    resources :offices do
      member do
        get 'managers'
        get 'agents'
      end
    end
  end

  # TODO: consolidate this somehow?
  concern :images_uploadable do
    resources :images, only: [:create, :destroy] do
      collection do
        put 'sort'
      end
    end
  end

  concern :documents_uploadable do
    resources :documents, only: [:create, :destroy] do
      collection do
        put 'sort'
      end
    end
  end

  concern :unit_images_uploadable do
    resources :unit_images, only: [:create, :destroy] do
      collection do
        put 'sort'
      end
      member do
        patch 'rotate'
      end
    end
  end

  get 'buildings/mass_edit/:id' => "buildings#mass_edit", as: :mass_edit
  post 'buildings/mass_edit_update/:id' => "buildings#mass_edit_update", as: :mass_edit_update
  resources :buildings, concerns: [:images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    member do
      get 'delete_modal'
      get 'delete_residential_listing_modal'
      get 'inaccuracy_modal'
      patch 'send_inaccuracy'
      get 'refresh_images'
      get 'refresh_documents'
      get 'filter_listings'
    end
    collection do
      get 'filter'
      get 'neighborhood_options'
    end
  end
  get "residential_listings/change_updated_at_tday" => "residential_listings#change_updated_at_tday", as: :change_updated_at_tday
  get "residential_listings/download_all_img/:id" => "residential_listings#download_all_img", as: :download_all_img
  get "residential_listings/swap_key_to_agent" => "residential_listings#swap_key_to_agent", as: :swap_key_to_agent
  get "residential_listings/store_office_for_return_key" => "residential_listings#store_office_for_return_key", as: :store_office_for_return_key
  get "residential_listings/claim_key/:id" => "residential_listings#claim_unit_key", as: :claim_unit_key
  get "residential_listings/return_key/:id" => "residential_listings#return_unit_key", as: :return_unit_key
  get "residential_listings/:id/delete_contact" => "residential_listings#delete_contact", as: :delete_contact_rental
  get "residential_listings/download_csv_active_new_reactivated_listings/:id" => "residential_listings#download_csv_active_new_reactivated_listings", as: :download_csv_active_new_reactivated_listings
  get "residential_listings/weekly_track" => "residential_listings#find_active_listing_weekly_basis", as: :weekly_track
  get "residential_listings/individual_se_list" => "residential_listings#individual_se_list", as: :individual_se_list
  get 'residential_listings/favorite_listings' => "residential_listings#favorite_listings", as: :residential_favorite_listings
  get 'sales_listings/:sales_listing_id/unit_images/:id/display_floor_image_sales' => "unit_images#display_floor_image_sales", as: :display_floor_image_sales
  get 'residential_listings/:residential_listing_id/unit_images/:id/display_floor_image' => "unit_images#display_floor_image", as: :display_floor_image
  get 'residential_listings/:residential_listing_id/unit_images/:id/display_tenant_sourced' => "unit_images#display_tenant_sourced", as: :display_tenant_sourced
  get 'residential_listings/:residential_listing_id/unit_images/:id/display' => "unit_images#display", as: :display
  get 'residential_listings/index_streeteasy' => "residential_listings#index_streeteasy", as: :index_streeteasy
  get 'residential_listings/index_main' => "residential_listings#index_main", as: :index_main
  get 'rooms_image_delete/:id' => "rooms#room_image_delete", as: :room_image_delete
  post 'rooms/:id' => "rooms#room_update", as: :room_update
  post 'rooms/:id/send_inaccuracy' => "rooms#send_inaccuracy", as: :send_inaccuracy_room
  resources :rooms
  get 'residential_listings/agent_rental' => "residential_listings#agent_rental", as: :agent_rental
  get 'residential_listings/media_index' => "residential_listings#media_index", as: :media_index
  get 'residential_listings/room_index' => "residential_listings#room_index", as: :room_index
  get 'residential_listings/download_image/:id' => "residential_listings#download_image", as: :download_image
  post 'residential_listings/generate_custom_email' => "residential_listings#generate_custom_email", as: :generate_custom_email
  get 'residential_listings/send_custom_email' => "residential_listings#send_custom_email", as: :send_custom_email
  post 'residential_listings/send_email_to_tenant/:id' => "residential_listings#send_email_to_tenant", as: :send_email_to_tenant
  post 'residential_listings/send_sms_to_tenant/:id' => "residential_listings#send_sms_to_tenant", as: :send_sms_to_tenant
  post 'residential_listings/add_to_photog_list/:id' => "residential_listings#add_to_photog_list", as: :add_to_photog_list
  get 'residential_listings/photographer_todo' => "residential_listings#photographer_todo", as: :photographer_todo
  get 'residential_listings/delete_all_image/:id' => "residential_listings#delete_all_image", as: :delete_all_image
  post 'residential_listings/photo_status_update/:id' => "residential_listings#photo_status_update", as: :photo_status_update
  get 'residential_listings/delete_from_photo_tag_list/:id' => "residential_listings#delete_from_photo_tag_list", as: :delete_from_photo_tag_list
  get 'residential_listings/claim_for_streeteasy' => "residential_listings#claim_for_streeteasy", as: :claim_for_streeteasy
  get 'residential_listings_active_by_agent/:id/:streeteasy_status' => "residential_listings#streeteasy_active_by_agent", as: :streeteasy_active_by_agent
  get 'delete_from_se_claim/:id' => "residential_listings#delete_from_se_claim", as: :delete_from_se_claim
  get 'residential_listings/rental_mobile_search' => "residential_listings#rental_mobile_search", as: :rental_mobile_search
  get 'residential_listings/search_result' => "residential_listings#rental_mobile_search_result", as: :rental_mobile_search_result
  resources :residential_listings, concerns: [:unit_images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    get :autocomplete_landlord_code, :on => :collection
    member do
      get 'delete_modal'
      get 'duplicate_modal'
      post 'duplicate'
      get 'inaccuracy_modal'
      patch 'send_inaccuracy'
      patch 'mark_app_submitted'
      get 'refresh_images'
      get 'refresh_documents'
    end
    collection do
      get 'filter'
      get 'fee_options'
      get 'print_list'
      get 'print_modal'
      get 'print_public'
      get 'print_private'
      post 'send_listings'
      get 'update_announcements'
      get 'update_announcements_mobile'
      get 'assign_modal'
      post 'assign'
      get 'unassign_modal'
      post 'unassign'
      post 'check_in'
      get 'check_in_options'
    end
  end
  
  get "residential_listings/syndication_page/disclaim/:id" => "residential_listings#disclaim_for_individual_syndication_page", as: :disclaim_for_individual_syndication_page
  get "residential_listings/syndication_page/claim/:id" => "residential_listings#claim_for_individual_syndication_page", as: :claim_for_individual_syndication_page
  get "residential_listings/disclaim/:id" => "residential_listings#disclaim_naked_apartment", as: :disclaim_naked_apartment
  get "residential_listings/claim/:id" => "residential_listings#claim_naked_apartment", as: :claim_naked_apartment
  get "residential_listings/agent_show/:id" => "residential_listings#agent_show", as: :agent_show
  get "/agent_residential_listing/:id/edit" => "residential_listings#agent_edit", as: :agent_edit
  patch "/agent_residential_listing/:id" => "residential_listings#agent_update", as: :agent_update
  get "/specific_residential_listing/:id/edit" => "residential_listings#specific_edit", as: :specific_edit
  patch "/specific_residential_listing/:id" => "residential_listings#specific_update", as: :specific_update
  post "residential_listings/access_email_generate" => "residential_listings#access_email_generate", as: :access_email_generate
  
  resources :sales_listings, concerns: [:unit_images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    get :autocomplete_seller_name, :on => :collection
    member do
      get 'delete_modal'
      get 'duplicate_modal'
      post 'duplicate'
      get 'inaccuracy_modal'
      patch 'send_inaccuracy'
      patch 'mark_app_submitted'
      get 'refresh_images'
      get 'refresh_documents'
    end
    collection do
      get 'filter'
      get 'neighborhoods_modal'
      get 'features_modal'
      get 'fee_options'
      get 'neighborhood_options'
      get 'print_list'
      get 'print_modal'
      get 'print_public'
      get 'print_private'
      post 'send_listings'
      get 'assign_modal'
      post 'assign'
    end
  end

  resources :landlord_contacts do
    collection { post :import }
  end

  get "landlords/:id/delete_contact" => "landlords#delete_contact", as: :delete_contact
  resources :landlords do
    get :autocomplete_landlord_code, :on => :collection
    collection do
      get 'filter'
    end
    member do
      get 'delete_modal'
      get 'filter_listings'
    end
  end

  resources :neighborhoods

  resources :building_amenities

  resources :commercial_listings, concerns: [:unit_images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    get :autocomplete_landlord_code, :on => :collection
    member do
      get 'delete_modal'
      get 'duplicate_modal'
      post 'duplicate'
      get 'inaccuracy_modal'
      patch 'send_inaccuracy'
      get 'refresh_images'
      get 'refresh_documents'
      patch 'mark_app_submitted'
    end
    collection do
      get 'filter'
      get 'update_subtype'
      get 'neighborhoods_modal'

      get 'print_list'
      get 'print_modal'
      get 'print_public'
      get 'print_private'
      post 'send_listings'
      get 'assign_modal'
      post 'assign'
    end
  end

  # designed to match nestio's API endpoints, so we can feed our data seamlessly to
  # our public-facing website
  namespace :api, :defaults => {:format => :json} do #, :path => "/", :constraints => {:subdomain => "api"}  do
    namespace :v1 do
      resources :agents, only: [:index, :show]
      resources :neighborhoods, only: [:index, :show]
      resources :listings, only: [:index, :show]
      resources :buildings, only: [:index, :show]
      resources :landlords, only: [:index, :show]
    end
  end

  resources :syndication, :defaults => { :format => 'rss' } do #:show #path:'public_feed',
    member do
      get 'naked_apts'
      get 'streeteasy'
      get 'trulia'
      get 'zillow'
      get 'nestio'
      get 'dotsignal'
      get 'hotpad'
      get 'rooms'
      get 'apartment'
      get 'zumper'
      get 'zumper_backup'
      get 'external_feed'
      get 'external_feed_no_rooms'
      get 'renthop'
      get 'rhexport'
      get 'test_watermark'
      get 'all_active_users'
    end
  end

  resources :roommates do
    member do
      get 'delete_modal'
      get 'match_modal'
      post 'match'
      get 'unmatch_modal'
      post 'unmatch'
    end
    collection do
      get 'filter'
      get 'print_list'
      post 'send_message'
      get 'download'
      get 'send_update'
      get 'match_multiple_modal'
      post 'match_multiple'
      get 'check_availability'
      patch 'mark_read'
      get :autocomplete_roommate_name
      get :autocomplete_user_email
      get :autocomplete_building_formatted_street_address
      get :get_units
      get 'destroy_multiple_modal'
      delete 'destroy_multiple'
    end
  end

  resources :roomsharing_applications do
    member do
      get 'delete_modal'
      get 'unarchive_modal'
      post 'unarchive'
      #get 'detail_modal'
    end
    collection do
      get 'filter'
      post 'send_message'
      get 'download'
    end
  end

  resources :user_waterfalls do
    member do
      get 'delete_modal'
      get 'edit_modal'
    end
    collection do
      get 'filter'
      get 'get_rate'
      get :autocomplete_user_name
    end
  end

  resources :announcements do
    member do
      get 'delete_modal'

    end
    collection do
      get :filter
    end
  end
  get 'announce' => 'announcements#new'
  get 'add_open_hours' => 'units#add_open_hours'
  resources :deals do
    member do
      get 'delete_modal'
    end
    collection do
      get :filter
      get :get_units
      get :autocomplete_building_formatted_street_address
      get :autocomplete_landlord_code
      get :autocomplete_user_name
    end
  end
end
