namespace :css do
  task :build do
    sh "npm run build:css"
  end
end
Rake::Task["assets:precompile"].enhance(["css:build"])