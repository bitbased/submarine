Submarine::Application.routes.draw do


  resources :dropbox do
    member do
      post 'upload'
    end
  end

  resources :projects do
    resources :time_entries
    resources :expense_entries
    resources :project_task_category_assignments
    resources :task_categories
    collection do
      post 'reserve', to: "projects#reserve"
      post 'release/:code', to: "projects#release"
    end
  end
  resources :project_participants
  resources :task_categories

  resources :activity_logs do
    member do
      post 'dismiss'
    end
  end


  get "/", :to => "sessions#new", :as => 'root'

  get 'login', to: 'sessions#new', as: 'login'
  get 'logout', to: 'sessions#destroy', as: 'logout'

  resources :sessions

  resources :dashboard do
    collection do
      get 'projects'
      get 'projects/:id/edit', to: redirect("/dashboard/projects")
      get 'projects/:id', to: redirect("/dashboard/projects")
      get 'clients'
    end
  end

  get '/syncronize/:sync' => "administration#external_syncronization"

  resources :administration do
    collection do
      get 'process_queue'
      get 'harvest_syncronization'
    end
  end

  resources :permalinks

  resources :time_entries

  resources :expense_entries

  resources :information

  resources :information_groups

  resources :roles

  resources :users do
    resources :time_entries
  end

  resources :tasks

  resources :contacts

  resources :clients

  scope "api" do
    resources :projects
    resources :clients
    resources :time_entries
    resources :information
    resources :information_groups
    resources :roles
    resources :users
    resources :tasks
    resources :contacts
  end

  get "new" => "submarine_accounts#new"
  get "account" => "submarine_accounts#edit"
  get "account/reset" => "submarine_accounts#reset"
  resources :submarine_accounts

end
