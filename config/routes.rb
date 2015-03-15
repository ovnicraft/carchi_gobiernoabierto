OpenIrekia::Application.routes.draw do

  resources :oauth_consumers do
    member do
      get :callback
    end
  end

  get '/admin/' => 'sadmin/news#home'

  get 'admin/pending' => 'admin/pending#index'
  get 'pending' => "admin/comments#pending", :format => "iphone", :as => :pending_admin_comments

  get "/:locale/web_tv/cat/:id" => "videos#cat", :as => :cat_videos
  # Agenda by departaments
  get ":locale/dept/:dept_label/events" => "events#index", :as => :dept_events
  get ":locale/dept/:dept_label/events/archive" => "events#index", :archive => true, :as => :dept_events_archive
  get ":locale/dept/:dept_label/events/:tag_label" => "events#index", :as => :dept_events4tag

  scope "/:locale", :locale => /es|eu|en|_LNG_/ do

    namespace :sadmin do
      resources  :news do
        resources :subtitles
        collection do
          get :published, :choose_criterio, :new_epub
          post :export_for_enet, :create_epub
          post :auto_complete_for_news_politicians_tag_list
        end
      end
      resources  :attachments
      resources  :events do
        collection do
          get :myfeed
          match :calendar, via: [:get, :post]
          get :list
          post :list
          get :week
          post :week
          post :auto_complete_for_event_politicians_tag_list
          post :auto_complete_for_event_place
        end
        member do
          get :mark_for_deletion
          put :delete
          post :unrelate
          post :auto_complete_for_event_related_news_title
          post :set_event_related_news_title
        end
      end

      resource :account, :controller => 'account', :only => [:edit, :show, :update]

    end

    namespace :admin do
      resources :room_managers, :only => [:index] if Settings.optional_modules.streaming

      resources :videos do
        collection do
          get :find_video, :channels
          post :create_with_subtitles
          post :auto_complete_for_video_tag_list
        end
        member do
          post :update_subtitles
          post :delete_subtitles
          put :publish
        end
      end

      resources :trees do
        resources :categories do
          collection do
            post :sort
          end
          member do
            get :edit_tags
          end
        end
      end

      resources :documents do
        member do
          get :comments
          put :update_comments_status
          get :edit_tags
          get :edit2
          put :publish
        end
        collection do
          post :auto_complete_for_document_tag_list_without_areas
        end
      end

      if Settings.optional_modules.proposals
        resources :proposals do
          member do
            get :comments
            get :edit_common
            put :publish
            put :update_status
            get :reject
            put :do_reject
          end
          collection do
            get :arguments
            post :auto_complete_for_proposal_tag_list
          end
        end
      end

      resources :arguments do
        member do
          put :approve
        end
      end

     if Settings.optional_modules.debates
      resources :debates do
        member do
          get :comments
          put :publish
          put :update_status
          get :common
          get :edit_common
          get :translations
        end
        collection do
          get :arguments
          post :auto_complete_for_debate_tag_list_without_hashtag
          post :auto_complete_for_debate_entity_organization_name
        end
        resources :entities, :controller => "debate_entities" do
          collection do
            post :sort
          end
        end
      end
     end

      resources :outside_organizations

      resources :images

      resources :materials

      resources :comments do
        collection do
          put :update_comments_status
        end
        member do
          put :update_status
          get :comments_on_item
          get :reject
          put :do_reject
        end
      end

      # Comentarios en webs externas
      resources :external_comments, :controller => 'external/comments' do
        collection do
          put :update_comments_status
        end
        member do
          put :mark_as_spam
          put :mark_as_ham
          put :update_status
          get :comments_on_item
          get :reject
          put :do_reject
        end
      end

      # Clientes del widget de comentarios
      resources :external_clients, :controller => 'external/clients'
      # Items de los clientes externos donde se ha incluido el widget.
      # NO se puede usar :has_many => [:external_items] porque no reconoce correctamente el controller.
      get 'external_clients/:external_client_id/items' => 'external/items#index', :as => :external_client_items

      resources :tags, :only => [:index, :update] do
        collection do
          get :find_duplicates
          post :merge
        end
        member do
          get :set_tag_name
          get :set_tag_kind
        end
      end

      resources :users do
        member do
          get :pwd_edit
          put :pwd_update
          get :make_admin
        end
        collection do
          get :search
        end
        resource :permissions
      end

      resources :people do
        member do
          put :change_status
        end
      end

     if Settings.optional_modules.streaming
      resources :stream_flows, :except => :show do
        member do
          put :update_status
        end
        collection do
          get :list
          get :order
          post :sort
        end
      end
     end

      resources :photos do
        collection do
          get :batch_edit
          put :batch_update
          get :find_photos
          get :orphane
          post :auto_complete_for_photo_tag_list
        end
      end

      resources :albums do
        member do
          post :choose_cover
          put :publish
        end
        collection do
          get :channels
          post :auto_complete_for_album_tag_list
        end
        resources :photos
      end

      resources :organizations

      resources :areas do |area|
        resources :users, :controller => "area_users" do
          collection do
            post :sort
            post :auto_complete_for_area_user_name_and_email
          end
        end
      end

      resources :stats, :only => :index do
        collection do
          get :contents
          get :news, :event, :video, :external_comments, :bulletin
          get :proposal if Settings.optional_modules.proposals
          get :debate if Settings.optional_modules.debates
        end
      end

      resources :event_locations

      resources :banners do
        collection do
          post :sort
        end
      end

      resources :sorganizations

     if Settings.optional_modules.headlines
      resources :headlines do
        collection do
          delete :delete_from_entzumena
          post :auto_complete_for_headline_tag_list_without_areas
        end
        member do
          put :update_area
        end
      end
     end

      resources :bulletins do
        collection do
          get :announce
          get :archive
          post :mark_candidates
          get :subscribers
        end
        member do
          post :program
        end
      end

      resources :bulletin_copies, :only => [:show, :create]

      resource :pending, :controller => 'pending', :only => [:index] do
        collection do
          put :approve
          put :spam
          put :reject
          get :edit_proposal
          delete :destroy, as: :destroy
        end
      end
    end

    ########################################################
    # PUBLIC
    ########################################################
    get "/" => "site#show", :as => :root_with_locale
    get "/signup" => "people#new", :as => :signup
    get "/login" => "sessions#new", :as => :login
    get "/mlogin" => "sessions#mobile", :as => :mlogin
    match "/logout" => "sessions#destroy", :as => :logout, :via => [:get, :delete]
    get "/nav_user_info" => "sessions#nav_user_info", :as => :nav_user_info
    get "/podcast" => "videos#podcast", :format => :xml, :as => :podcast
    get "/podcast.:format" => "videos#podcast"

    resources :areas, :only => [:index, :show] do
      collection do
        get :search
      end
      member do
        get :activity
        get :what
      end
      resources :politicians, :only => [:index]

      get 'news' => 'news#index', :as => :news
      resources :events, :only => [:index] do
        collection do
          get :list
        end
      end
      resources :proposals, :only => [:index] if Settings.optional_modules.proposals
      resources :debates, :only => [:index] if Settings.optional_modules.debates
      resources :videos, :only => [:index]
      resources :albums, :only => [:index]
      resources :answers, :only => :index
    end

    resources :politicians, :only => [:index, :show] do
      member do
        get :what
      end

      get 'news' => 'news#index'
      resources :events, :only => [:index] do
        collection do
          get :list
        end
      end
      resources :proposals, :only => [:index, :new] if Settings.optional_modules.proposals
      resources :videos, :only => [:index]
      resources :albums, :only => [:index]
      resources :attachments, :only => [:new, :create]
    end

    resource :account,  :controller => 'account', :except => [:new, :create] do
      member do
        get :pwd_edit
        put :pwd_update
        get :confirm_delete
        get :activate
        get :settings
        post :image
        post :photo
        get :activity
        get :proposals if Settings.optional_modules.proposals
        get :actions
        get :followings
        get :notifications
      end
    end

    resources :people, :only => [:new, :edit, :create, :update] do
      collection do
        post :validate_field
        get :intro
      end
    end

    resources :videos, :path => :web_tv, :only => [:new, :index, :show] do
      resources :comments
      collection do
        get :closed_captions
        get :summary
      end
    end

    if Settings.optional_modules.proposals
      resources :proposals, :except => [:edit, :update, :destroy] do
        resources :comments
        collection do
          post :image
          get :summary
          get :department
        end
        resources :votes, only: [:create]
        resources :arguments, only: [:create]
      end
    end

   if Settings.optional_modules.debates
    resources :debates, :only => [:index, :show] do
      resources :comments
      member do
        get :compress
      end
      collection do
        get :department
      end
      resources :votes, :only => :create
      resources :arguments, :only => :create
    end
   end

    get '/questions/:id' => 'proposals#show', :as => :question if Settings.optional_modules.proposals

    resources :pages, :only => [:show]

    # Mantain old URLs
    get '/gallery' => "albums#index", :as => :gallery
    get '/gallery/:cat' => "albums#index", :as => :cat_gallery

    resources :photos, :only => [:show]
    get '/albums/cat/:id' => 'albums#cat', :as => :cat_albums
    resources :albums, :only => [:index, :show]
    get '/albums/:id/photos/:photo_id' => "albums#show", :requirements => {:photo_id => /\d+/}, :as => :album_photo

    resources :news, :only => [:index, :show] do
      collection do
        get :image
        get :summary
        get :department
        get :organization        
      end
      member do
        get :compress
        get :department
        get :organization     
      end
      resources :comments
    end

    get 'hemeroteca', to: "news#index", as: :hemeroteca

    resources :events, :only => [:index, :show] do
      collection do
        get :myfeed
        get :list
        get :summary
        get :calendar
        get :department
        get :organization
      end
    end

    # To enable posibility of reporting abuse of comments, include: :report_abuse => :post
    resources :comments do
      member do
        get :photo
      end
      collection do
        get :list
        get :department
      end
    end

    resources :external_comments_item, :only => [:show]

    resources :tags, :only => [:index, :show] do
      member do
        post :search
      end
    end

    resource :session, :only => [:new, :create, :destroy] do
      collection do
        get :email_activation
        get :mobile
        get :auth_info
      end
    end

    if Rails.application.secrets["twitter"]
      resource :twitter_session, :only => [:create, :destroy] do
        member do
          get :finalize
        end
      end
    end

    if Rails.application.secrets["facebook"]
      resource :fb_session, :only => [:create] do
        collection do
          get :finalize
        end
      end
    end

    if Rails.application.secrets["googleplus"]
      resource :googleplus_session, :only => [:create] do
        collection do
          get :finalize
        end
      end
    end

    resources :search, :controller => :search, :except => [:index] do
      collection do
        get :get_create
      end
    end

    get '/site/page/:label' => 'site#page', :requirements => {:label => /\w+/}, :as => :page_site

    # old routes
    get '/site/tos' => "site#page", :as => "tos"
    get '/site/about' => "site#page", :as => "about"
    get '/site/privacy' => "site#page", :as => "privacy"
    # /old routes

    resource :site, :controller => :site, :only => [:show] do
      member do
        get :legal, :search, :contact, :splash, :snetworking, :sitemap, :feeds, :email_item, :home, :user_default, :setup, :setup2
        post :send_contact, :send_email
        put :update_setup
      end
    end

    get '/transparency' => 'news#index', :as => :transparency

   if Settings.optional_modules.streaming
    resources :streamings, :only => [:index, :show] do
      member do
        get :live
      end
    end
   end
    resources :recommendation_ratings, :only => [:create]
    resources :banners, :only => [:index]

    get '/cached/news/:id' => 'cached#show', :requirements => {:type => 'Document'}, :as => :cached_news

    resources :followings do
      collection do
        get :state
      end
    end

    resources :users, :only => [:show] do
      member do
        get :connect
        get :actions
        get :followings
        get :agenda
        get :settings
      end
      resources :proposals, :only => [:index] if Settings.optional_modules.proposals
    end

    resource :mob_app, :controller => "mob_app", :except => [:new, :create, :edit, :update, :destroy], :format => "json" do
      member do
        get :news
        get :events
        get :photos
        get :videos
        get :appdata
        get :about
        get :search
        get :tags
        get :areas
        get :area
        get :v3
        get :v4
        get :team
        get :argazki
        get :root
        get :proposals if Settings.optional_modules.proposals
        get :debates if Settings.optional_modules.debates
        get :politician
      end

      resource :iui, :controller => 'mob_app/iui', :only => [:new, :create] do
        collection do
          post :step
        end
      end
    end

    resources :stats, :only => [:index]
    resources :orders, :only => [] do
      collection do
        post :search
      end
    end
    get 'orders/:no_orden' => 'orders#show', :as => :order

    resources :journalists, :only => [:new, :create]
    resources :answers, :only => [:index]
    get '/c/:id' => "clickthroughs#track", :as => :clickthrough

    resources :bulletin_copies, :only => :show
    get '/bulletin_subscriptions/new/:id' => "bulletin_subscriptions#new", :requirements => {:id => /[\d\w]+/}, :as => :new_bulletin_subscription

    resources :bulletin_subscriptions, :only => [:index, :create, :edit, :destroy]
    resources :password_resets

      resource :participation, :controller => "participation", :only => [:show] do
        member do
          get :summary
        end
      end
    namespace :embed do
      resource :comment, :only => [:show]
      get '/login' => 'sessions#new', :as => :login
      match '/logout' => 'sessions#destroy', :as => :logout, :via => [:get, :delete]
      get '/logged', to: 'sessions#show', as: :logged
      resource :session, :only => [:new, :create, :destroy] do
        collection do
          get :password_reset
        end
      end
    end
  end

  get '/mob_app/:v' => "mob_app#show", :requirements => {:v => /\d+/}, :as => :mov_version
  get '/mob_app/v3/:v' => "mob_app#v3", :requirements => {:v => /\d+/}, :as => :mov_v3_version
  get '/mob_app/v4/:v' => "mob_app#v4", :requirements => {:v => /\d+/}, :as => :mov_v4_version
  get '/mob_app/:action:locale' => "mob_app", :requirements => {:locale => /(es|eu|en|_LNG_)/}, :as => :mov_news_version

  # The priority is based upon order of creation: first created -> highest priority.
  root :to => 'site#show'
  get "/lang" => "site#splash", :as => :lang

  get '/iphone' => 'site#show', :format => "html", :path_prefix => ':locale', :requirements => {:locale => /(es|eu|en)/}, :as => :iphone
  get '/iphone' => "site#show", :format => "html", :locale => "es"

  get '/android' => "site#show", :format => "html", :path_prefix => ':locale', :requirements => {:locale => /(es|eu|en)/}, :as => :android
  get '/android' => "site#show", :format => "html", :locale => "es"

  # See how all your routes lay out with "rake routes"

  # Install the default routes as the lowest priority.
  # Note: These default routes make all actions in every controller accessible via GET requests. You should
  # consider removing the them or commenting them out if you're using named routes and resources.
  get ':controller(/:action(/:id))'
  get ':controller(/:action(/:id.:format))'

end
