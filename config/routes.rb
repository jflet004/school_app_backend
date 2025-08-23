Rails.application.routes.draw do
  resources :students do
      collection do
        get :export   # /students/export(.:format) supports .csv and .xlsx
      end
      resources :parent_contacts, only: [:index, :create, :update, :destroy, :show]
  end
end
