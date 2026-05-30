Rails.application.routes.draw do
  devise_for :users

  root "home#index"
  get "/c/:slug", to: "public/churches#show", as: :public_church

  namespace :platform do
    root "churches#index"

    resources :churches, param: :public_id, only: %i[index show new create edit update] do
      member do
        patch :activate
        patch :deactivate
      end

      resources :church_memberships, path: "admins", only: %i[new create]
    end
  end

  resources :churches, param: :public_id, only: %i[index show] do
    namespace :admin, module: :church_admin, as: :admin do
      root "dashboard#index"

      resources :roles, param: :public_id, only: %i[index show new create edit update] do
        member do
          patch :activate
          patch :deactivate
          patch :permissions, action: :update_permissions
        end
      end

      resources :memberships, controller: :church_memberships, param: :public_id, only: %i[index new create edit update] do
        member do
          patch :activate
          patch :deactivate
        end
      end
      resources :members, param: :public_id, only: %i[index show new create edit update] do
        collection do
          get :search
        end
        member do
          patch :activate
          patch :deactivate
        end
      end

      resources :ministries, param: :public_id, only: %i[index show new create edit update] do
        collection { get :search }
        member do
          patch :activate
          patch :deactivate
          patch :members, action: :update_members
        end
      end

      resource :settings, only: %i[show update], controller: :settings

      resources :service_times, param: :public_id, only: %i[index new create edit update] do
        member do
          patch :activate
          patch :deactivate
        end
      end

      resources :families, param: :public_id, only: %i[index show new create edit update] do
        member do
          patch :activate
          patch :deactivate
          patch :members, action: :update_members
        end
      end

      resources :events, param: :public_id, only: %i[index show new create edit update] do
        member do
          patch :cancel
          patch :reschedule
          get :attendance
          patch :attendance, action: :update_attendance
        end
      end

      resources :boards, param: :public_id, only: %i[index show new create edit update] do
        member do
          patch :activate
          patch :deactivate
          patch :positions, action: :update_positions
        end
      end

      resources :occupations, param: :public_id, only: %i[index new create edit update] do
        collection { get :search }
        member do
          patch :activate
          patch :deactivate
        end
      end

      resources :skills, param: :public_id, only: %i[index new create edit update] do
        collection { get :search }
        member do
          patch :activate
          patch :deactivate
        end
      end

      resources :members, param: :public_id, only: [] do
        member do
          patch :assign_occupations, controller: "member_occupations", action: :assign
          patch :assign_skills,      controller: "member_skills",      action: :assign
          patch :assign_ministries,  controller: "member_ministries",  action: :assign
        end
        resources :occupations, param: :public_id, only: %i[new create edit update destroy], controller: "member_occupations"
        resources :skills, param: :public_id, only: %i[new create edit update destroy], controller: "member_skills"
      end

      get "service_directory" => "service_directory#index", as: :service_directory

      get "reports", to: "reports#index", as: :reports
      get "reports/:report", to: "reports#show", as: :report

      resources :profile_change_requests, param: :public_id, only: %i[index show] do
        member do
          patch :approve
          patch :reject
        end
      end
    end

    namespace :portal, module: :member_portal, as: :member_portal do
      resource :profile, only: %i[show]
      resources :profile_change_requests, only: %i[new create]
      resources :events, param: :public_id, only: %i[index show] do
        member do
          post :rsvp
        end
      end
    end

    namespace :pastor, module: :pastor, as: :pastor do
      resources :pastoral_notes, param: :public_id
      resources :members, param: :public_id, only: %i[index show]
    end

    namespace :ministry_leader, module: :ministry_leader, as: :ministry_leader do
      resources :ministries, param: :public_id, only: %i[index show]
      resources :events, param: :public_id, only: %i[index show]
    end
  end

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
