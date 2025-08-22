Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins "http://localhost:5173", "http://localhost:3000", /\Ahttp:\/\/localhost:\d+\z/
    resource "*",
      headers: :any,
      methods: %i[get post put patch delete options head],
      expose: ["Authorization", "Content-Type"]
  end
end
