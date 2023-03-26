# frozen_string_literal: true

require 'lighstorm'
require 'nitrox-core'

module BootController
  def self.boot!
    NitroxCore.discovery.broadcast!

    Lighstorm.inject_middleware!(lambda do |key, &block|
      NitroxCore.monitoring.metrify(:grpc, :out, key, &block)
    end)

    NitroxCore.logger.info("Starting server on port #{ENV.fetch('NITROX_PORT')}")
  end
end
