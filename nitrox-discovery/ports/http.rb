# frozen_string_literal: true

require 'nitrox-core'

require_relative '../components/services'
require_relative '../controllers/services'

module HTTP
  def self.fetch(service, path)
    NitroxCore.monitoring.http.out(service, path) do
      url = "http://#{Services.instance.addresses[service]['address']}"

      JSON.parse(Faraday.get(url).body)
    end
  end

  def self.routes(route, request, response)
    NitroxCore.monitoring.setup(route)

    route.root do
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ServicesController.index
        end
      end
    end

    route.get String do |service|
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ServicesController.address(service)
        end
      end
    end

    route.put String do |service|
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ServicesController.update(service, request.body.read)
        end
      end
    end
  end
end
