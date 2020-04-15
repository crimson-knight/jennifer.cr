require "./shared_helpers"
require "./spec_helper"

POOL_SIZE = 3
TIME_TO_SLEEP = 3

if Spec.adapter != "mysql"
  puts "This test only available for mysql adapter"
  exit 0
end

Jennifer::Config.configure do |conf|
  conf.read("./examples/database.yml", Spec.adapter)
  conf.logger.level = :info
  conf.max_pool_size = POOL_SIZE
  conf.initial_pool_size = POOL_SIZE
  conf.max_idle_pool_size = POOL_SIZE
  conf.checkout_timeout = 1.0

  conf.user = ENV["DB_USER"] if ENV["DB_USER"]?
  conf.password = ENV["DB_PASSWORD"] if ENV["DB_PASSWORD"]?
end

Spec.before_each do
  (Jennifer::Model::Base.models - [Jennifer::Migration::Version]).each { |model| model.all.delete }
end

describe "Concurrent execution" do
  adapter = Jennifer::Adapter.adapter
  tread_count = POOL_SIZE + 1

  describe "Jennifer::Adapter::Base" do
    sleep_command =
      case Spec.adapter
      when "mysql"
        "SLEEP(#{TIME_TO_SLEEP})"
      when "postgres"
        "pg_sleep(#{TIME_TO_SLEEP})"
      else
        raise "Unknown adapter #{Spec.adapter}"
      end

    describe "#exec" do
      it "raises native db exception" do
        ch = Channel(String).new
        tread_count.times do
          spawn do
            begin
              adapter.exec("CREATE temporary table table1 select #{sleep_command} as col")
              ch.send("")
            rescue e : Exception
              ch.send(e.class.to_s)
            end
          end
        end

        responses = (0...tread_count).map { ch.receive }
        responses.should contain("DB::PoolTimeout")
      end
    end

    describe "#query" do
      it "raises native db exception" do
        ch = Channel(String).new
        tread_count.times do
          spawn do
            begin
              adapter.query("SELECT #{sleep_command}") do |rs|
                rs.each do
                  rs.columns.size.times do
                    rs.read
                  end
                end
              end

              ch.send("")
            rescue e : Exception
              ch.send(e.class.to_s)
            end
          end
        end

        responses = (0...tread_count).map { ch.receive }
        responses.should contain("DB::PoolTimeout")
      end
    end

    describe "#scalar" do
      it "raises native db exception" do
        ch = Channel(String).new
        tread_count.times do
          spawn do
            begin
              adapter.scalar("SELECT MAX(#{sleep_command})")
              ch.send("")
            rescue e : Exception
              ch.send(e.class.to_s)
            end
          end
        end

        responses = (0...tread_count).map { ch.receive }
        responses.should contain("DB::PoolTimeout")
      end
    end
  end
end
