Rails.application.routes.draw do
  devise_for :users

  root "home#index"

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
      root "roles#index"

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
        member do
          patch :activate
          patch :deactivate
        end
      end

      resources :ministries, param: :public_id, only: %i[index show new create edit update] do
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
