# frozen_string_literal: true

require 'nitrox-core'

module NodesController
  def self.myself(headers, params)
    connection = headers['Nitrox-Connection-Id'] || params['connection_id']

    NitroxCore.lighstorm.ensure!(connection)

    Lighstorm::Lightning::Node.as(connection).myself.to_h
  end
end
