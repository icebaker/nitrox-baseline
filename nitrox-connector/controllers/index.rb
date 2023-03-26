# frozen_string_literal: true

module IndexController
  def self.handler
    {
      project: ENV.fetch('NITROX_SERVICE'),
      version: '0.0.1'
    }
  end
end
