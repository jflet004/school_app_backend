Rails.application.routes.draw do
  resources :students do
    collection { get :export }
    resources :parent_contacts, only: [:index, :create, :update, :destroy, :show]
  end

  # Canonical courses (catalog) — NOT nested
  resources :courses

  # Time slots belong to teachers and courses — but we’ll nest under teacher for convenience
  resources :teachers do
    resources :course_offerings, only: [:index, :show, :create, :update, :destroy]
  end
end
