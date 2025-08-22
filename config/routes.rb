Rails.application.routes.draw do
  resources :students do
    resources :parent_contacts, only: [:index, :create, :update, :destroy, :show]
  end
end
