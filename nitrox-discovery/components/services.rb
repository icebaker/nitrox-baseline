# frozen_string_literal: true

require 'singleton'
require 'yaml'

class Services
  include Singleton

  DATA_PATH = 'data/addresses.yml'

  attr_reader :addresses

  def initialize
    File.write(DATA_PATH, YAML.dump({})) unless File.exist?(DATA_PATH)

    @addresses = {}
  end

  def update(service, value)
    @addresses[service] = {
      'service' => service,
      'address' => value,
      'updated_at' => Time.now
    }

    File.write(DATA_PATH, YAML.dump(@addresses))
  end
end
