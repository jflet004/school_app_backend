Rails.application.routes.draw do
  resources :students do
    collection { get :export }
    resources :parent_contacts, only: [:index, :create, :update, :destroy, :show]
  end

  resources :teachers do
    resources :courses, only: [:index, :create, :update, :destroy, :show]
  end
end
