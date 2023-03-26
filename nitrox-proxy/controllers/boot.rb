# frozen_string_literal: true

require 'nitrox-core'

module BootController
  def self.boot!
    NitroxCore.discovery.broadcast!

    NitroxCore.logger.info("Starting server on port #{ENV.fetch('NITROX_PORT')}")
  end
end
