# lib/tasks/reseed.rake
namespace :db do
  desc "Drop, create, migrate, and seed (with optional CHILDREN/ADULTS env vars)"
  task reseed: :environment do
    Rake::Task["db:drop"].invoke
    Rake::Task["db:create"].invoke
    Rake::Task["db:migrate"].invoke
    Rake::Task["db:seed"].invoke
  end
end
