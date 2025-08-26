# config/routes.rb
Rails.application.routes.draw do
  resources :students do
    collection { get :export }
    resources :parent_contacts, only: [:index, :create, :update, :destroy, :show]
  end

  # Canonical catalog
  resources :courses

  # Time slots (CourseOfferings)
  resources :teachers do
    resources :course_offerings, only: [:index, :show, :create, :update, :destroy]
  end
  # Also provide a top-level index for global filtering/sorting
  resources :course_offerings, only: [:index, :show, :update, :destroy]

  # Enrollments: create/list under an offering; manage/charge by id
  resources :course_offerings, only: [] do
    resources :enrollments, only: [:index, :create]
  end
  resources :enrollments, only: [:show, :update, :destroy] do
    member { get :charge } # /enrollments/:id/charge?year=2025&month=9
  end
end
