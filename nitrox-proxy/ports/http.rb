# frozen_string_literal: true

require 'nitrox-core'

require_relative '../controllers/proxy'

module HTTP
  def self.pull(service, address, path, headers, verb)
    timeout = 5.0

    timeout = 60 * 5 if service == 'nitrox-router'

    NitroxCore.monitoring.http.out(service, '/*') do
      Faraday::Connection.new.send(verb, "http://#{address}#{path}", nil, headers) do |request|
        request.options.timeout = timeout
      end
    end
  end

  def self.push(service, address, path, headers, body, verb)
    timeout = 5.0

    NitroxCore.monitoring.http.out(service, '/*') do
      Faraday::Connection.new.send(verb, "http://#{address}#{path}", body, headers) do |request|
        request.options.timeout = timeout
      end
    end
  end

  def self.routes(route, request, response)
    NitroxCore.monitoring.setup(route)

    route.root do
      NitroxCore.roda.safely_ensure_json(response) do
        NitroxCore.monitoring.http.in(request) do
          ProxyController.index
        end
      end
    end

    route.on String, method: :get do
      NitroxCore.roda.safely_ensure_json(response) do
        result = NitroxCore.monitoring.http.in(request) do
          ProxyController.forward_pull(request, :get)
        end

        response.status = result[:status]
        apply_headers!(response, result[:headers])
        result[:body]
      end
    end

    route.on String, method: :put do
      NitroxCore.roda.safely_ensure_json(response) do
        result = NitroxCore.monitoring.http.in(request) do
          ProxyController.forward_push(request, :put)
        end

        response.status = result[:status]
        apply_headers!(response, result[:headers])
        result[:body]
      end
    end

    route.on String, method: :post do
      NitroxCore.roda.safely_ensure_json(response) do
        result = NitroxCore.monitoring.http.in(request) do
          ProxyController.forward_push(request, :post)
        end

        response.status = result[:status]
        apply_headers!(response, result[:headers])
        result[:body]
      end
    end

    route.on String, method: :delete do
      NitroxCore.roda.safely_ensure_json(response) do
        result = NitroxCore.monitoring.http.in(request) do
          ProxyController.forward_pull(request, :delete)
        end

        response.status = result[:status]
        apply_headers!(response, result[:headers])
        result[:body]
      end
    end
  end

  def self.apply_headers!(response, headers)
    return if headers.nil?

    headers.each_key do |key|
      response.headers[key.to_s] = headers[key]
    end
  end
end
