# frozen_string_literal: true

require 'nitrox-core'

require_relative '../ports/http'

module ProxyController
  def self.index
    {
      service: ENV.fetch('NITROX_SERVICE'),
      version: '0.0.1'
    }
  end

  def self.forward_pull(request, verb)
    path = request.url.split(%r{://.*?/})[1]
    service = path.split('/').first
    path = path.sub(/.*#{service}/, '')
    address = NitroxCore.discovery.fetch(service)

    headers = request.env.select { |k, _v| k.start_with? 'HTTP_' }
                     .transform_keys { |k| k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-') }

    begin
      response = HTTP.pull(service, address, path, headers, verb)

      {
        status: response.status,
        body: response.body,
        headers: response.headers
      }
    rescue StandardError => e
      {
        status: 500,
        body: {
          error: e.class,
          message: e.message,
          backtrace: e.backtrace,
        },
        headers: nil
      }
    end
  end

  def self.forward_push(request, verb)
    path = request.url.split(%r{://.*?/})[1]
    service = path.split('/').first
    path = path.sub(/.*#{service}/, '')
    address = NitroxCore.discovery.fetch(service)

    headers = request.env.select { |k, _v| k.start_with? 'HTTP_' }
                     .transform_keys { |k| k.sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-') }

    begin
      response = HTTP.push(service, address, path, headers, request.body.read, verb)

      {
        status: response.status,
        body: response.body,
        headers: response.headers
      }
    rescue StandardError => e
      {
        status: 500,
        body: {
          error: e.class,
          message: e.message,
          backtrace: e.backtrace,
        },
        headers: nil
      }
    end
  end
end
