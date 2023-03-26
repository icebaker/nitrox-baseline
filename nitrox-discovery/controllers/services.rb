# frozen_string_literal: true

require 'nitrox-core'

require_relative '../components/services'
require_relative '../ports/http'

module ServicesController
  def self.index
    {
      service: ENV.fetch('NITROX_SERVICE'),
      version: '0.0.1',
      services: Services.instance.addresses
    }
  end

  def self.address(service)
    Services.instance.addresses[service]
  end

  def self.update(service, value)
    Services.instance.update(service, value.to_s)
    address(service)
  end

  def self.boot!
    Services.instance.update(ENV.fetch('NITROX_SERVICE').sub('/', '-'), "#{ENV.fetch('NITROX_HOST')}:#{ENV.fetch('NITROX_PORT')}")
    Services.instance.update('redpanda', ENV.fetch('NITROX_REDPANDA'))
    Services.instance.update('redpanda-console', ENV.fetch('NITROX_REDPANDA_CONSOLE'))
    Services.instance.update('memcached', ENV.fetch('NITROX_MEMCACHED'))
    Services.instance.update('badger-db', ENV.fetch('NITROX_BADGER_DB'))
  end
end
