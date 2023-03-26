# frozen_string_literal: true

require 'nitrox-core'

require_relative '../controllers/index'
require_relative '../controllers/connections'
require_relative '../controllers/nodes'

module HTTP
  def self.fetch(service, path)
    NitroxCore.monitoring.http.out(service, path) do
      NitroxCore.api.fetch(service, path)
    end
  end

  def self.routes(route, request, response)
    NitroxCore.monitoring.setup(route)

    route.root do
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          IndexController.handler
        end
      end
    end

    route.delete 'connections' do
      NitroxCore.roda.safely_ensure_json(response) do
        result = NitroxCore.monitoring.http.in(request) do
          ConnectionsController.destroy(NitroxCore.roda.headers(request), request.params)
        end

        response.status = result[:status]
        result[:body]
      end
    end

    route.get 'connections' do
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ConnectionsController.index
        end
      end
    end

    route.get 'connections/badger' do
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ConnectionsController.badger
        end
      end
    end

    route.get 'connections', String do |id|
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ConnectionsController.find_by_id(id)
        end
      end
    end

    route.get 'nodes/myself' do
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          NodesController.myself(NitroxCore.roda.headers(request), request.params)
        end
      end
    end

    route.post 'connections' do
      NitroxCore.roda.safely_ensure_json(response) do
        result = NitroxCore.monitoring.http.in(request) do
          ConnectionsController.create(
            NitroxCore.roda.headers(request),
            NitroxCore.helpers.hash.symbolize_keys(
              JSON.parse(request.body.read)
            )
          )
        end

        response.status = result[:status]
        result[:body]
      end
    end
  end
end
