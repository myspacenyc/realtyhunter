Rails.application.routes.draw do

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

  root :to => 'static_pages#home'
  
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
    end
  end

  resources :buildings, concerns: [:images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    member do
      get 'delete_modal'
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

  #resources :residential_forms, only: [:new, :create, :edit, :update]

  resources :residential_listings, concerns: [:unit_images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    get :autocomplete_landlord_code, :on => :collection
    member do
      get 'delete_modal'
      get 'duplicate_modal'
      post 'duplicate'
      get 'inaccuracy_modal'
      patch 'send_inaccuracy'
      get 'take_off_modal'
      patch 'take_off'
      get 'refresh_images'
      get 'refresh_documents'
    end
    collection do
      get 'filter'
      get 'neighborhoods_modal'
      get 'features_modal'
      get 'fee_options'

      get 'print_list'
      get 'print_modal'
      get 'print_public'
      get 'print_private'
      post 'send_listings'
    end
  end

  resources :sales_listings, concerns: [:unit_images_uploadable, :documents_uploadable] do
    get :autocomplete_building_formatted_street_address, :on => :collection
    get :autocomplete_seller_name, :on => :collection
    member do
      get 'delete_modal'
      get 'duplicate_modal'
      post 'duplicate'
      get 'inaccuracy_modal'
      patch 'send_inaccuracy'
      get 'take_off_modal'
      patch 'take_off'
      get 'refresh_images'
      get 'refresh_documents'
    end
    collection do
      get 'filter'
      get 'neighborhoods_modal'
      get 'features_modal'
      get 'fee_options'

      get 'print_list'
      get 'print_modal'
      get 'print_public'
      get 'print_private'
      post 'send_listings'
    end
  end

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
    end
  end

  # designed to match nestio's API endpoints, so we can feed our data seamlessly to 
  # our public-facing website
  namespace :api, :defaults => {:format => :json} do #, :path => "/", :constraints => {:subdomain => "api"}  do
    namespace :v1 do
      resources :agents, only: [:index, :show]
      resources :neighborhoods, only: [:index, :show]
      resources :listings, only: [:index, :show]
    end
  end

  resources :syndication, :defaults => { :format => 'rss' } do #:show #path:'public_feed', 
    member do
      get 'naked_apts'
      get 'streeteasy'
      get 'trulia'
    end
  end

  resources :roommates do
    get :autocomplete_roommate_name, :on => :collection
    member do
      get 'delete_modal'
      get 'unarchive_modal'
      post 'unarchive'
    end
    collection do 
      get 'filter'
      get 'print_list'
      post 'send_message'
      get 'download'
      get 'send_update'
    end
  end

  namespace :forms do
    resources :contact_us, only: [:index, :destroy] do
      member do
        get 'delete_modal'
        get 'unarchive_modal'
        post 'unarchive'
        get 'detail_modal'
      end
      collection do
        get 'filter'
        post 'send_message'
        get 'download'
        get :autocomplete_wufoo_contact_us_form_name
      end
    end

    resources :partner, only: [:index, :destroy] do
      member do
        get 'delete_modal'
        get 'unarchive_modal'
        post 'unarchive'
        get 'detail_modal'
      end
      collection do
        get 'filter'
        post 'send_message'
        get 'download'
        get :autocomplete_wufoo_partner_form_name
        get :autocomplete_wufoo_partner_form_address_street_address
      end
    end

  # NOTE: we have decided to not use these 2 forms:

  #   resources :residential_listings, only: [:index, :destroy] do
  #     member do
  #       get 'delete_modal'
  #       get 'unarchive_modal'
  #       post 'unarchive'
  #       get 'detail_modal'
  #     end
  #     collection do
  #       get 'filter'
  #       post 'send_message'
  #       get 'download'
  #       get :autocomplete_wufoo_listings_form_name
  #       get :autocomplete_wufoo_listings_form_email
  #     end
  #   end

  #   resources :commercial_listings, only: [:index, :destroy] do
  #     member do
  #       get 'delete_modal'
  #       get 'unarchive_modal'
  #       post 'unarchive'
  #       get 'detail_modal'
  #     end
  #     collection do
  #       get 'filter'
  #       post 'send_message'
  #       get 'download'
  #       get :autocomplete_wufoo_listings_form_name
  #       get :autocomplete_wufoo_listings_form_email
  #     end
  #   end
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
      #get :autocomplete_wufoo_listings_form_name
      #get :autocomplete_wufoo_listings_form_email
    end
  end

  resources :user_waterfalls do
    collection do
      get 'filter'
      get 'get_rate'
      get :autocomplete_user_name
      #get :autocomplete_child_agent_name
    end
  end
    
end