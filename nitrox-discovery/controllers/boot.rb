# frozen_string_literal: true

require 'nitrox-core'

require_relative 'services'

module BootController
  def self.boot!
    ServicesController.boot!

    NitroxCore.logger.info("Starting server on port #{ENV.fetch('NITROX_PORT')}")
  end
end
