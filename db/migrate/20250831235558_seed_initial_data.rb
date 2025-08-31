class SeedInitialData < ActiveRecord::Migration[7.1]
  def up
    say_with_time "Loading db/seeds.rb" do
      seed_file = Rails.root.join("db/seeds.rb")
      if File.exist?(seed_file)
        load seed_file
      else
        Rails.logger.warn("Seed file not found: #{seed_file}")
      end
    end
  end

  def down
    say "No-op for seeds"
  end
end