# frozen_string_literal: true

require 'babosa'
require 'nitrox-core'

module ConnectionsController
  def self.badger
    NitroxCore.badger.get('connections')
  end

  def self.connections
    if NitroxCore.badger.exists?('connections')
        connections = NitroxCore.badger.get('connections')
      else
        connections = {
          default: {},
          custom: {}
        }
      end

    connections[:default].delete(:error) if connections[:default]

    connections[:custom].keys.each do |id|
      connections[:custom][id].delete(:error)
    end

    begin
      default = Lighstorm::Connection.default

      connections[:default] = {
        state: Lighstorm::Connection.default.slice(
          :connection, :address, :certificate, :host, :macaroon, :port
        )
      }

      connections[:default][:node] = Lighstorm::Lightning::Node.myself.to_h
      connections[:default][:id] = "default@#{connections[:default][:node][:public_key]}"
    rescue => e
      connections[:default] = {} unless connections.key?(:default)
      connections[:default][:id] = 'default'
      connections[:default][:node] = nil
      connections[:default][:error] = {
          class: e.class,
          message: e.message,
          backtrace: e.backtrace,
        }
    end

    if ENV.fetch('LIGHSTORM_LND_ADDRESS', nil).nil?
      connections.delete(:default)
    end

    connections[:custom].values.each do |connection|
      begin
        connection.delete(:error)

        if connection[:config][:connect].nil? || connection[:config][:connect].empty?
          Lighstorm::Connection.add!(connection[:config][:name], **connection[:config].slice(
            :address, :certificate, :macaroon, :certificate_path, :macaroon_path
          ))
        else
          Lighstorm::Connection.add!(connection[:config][:name], connection[:config][:connect])
        end

        connection[:state] = Lighstorm::Connection.for(connection[:config][:name]).slice(
          :connection, :address, :certificate, :host, :macaroon, :port
        )

        connection[:node] = Lighstorm::Lightning::Node.as(connection[:config][:name]).myself.to_h
        connection[:id] = "#{connection[:config][:name]}@#{connection[:node][:public_key]}"
      rescue => e
        connection[:node] = nil
        connection[:id] = "#{connection[:config][:name]}"
        connection[:error] = {
          class: e.class,
          message: e.message,
          backtrace: e.backtrace,
        }
      end
    end

    NitroxCore.badger.set('connections', connections)

    connections
  end

  def self.find_by_id(id)
    connections = self.connections

    return connections[:default][:state] if connections[:default] && connections[:default][:id] == id

    connection = connections[:custom].values.find do |connection|
      connection[:id] == id
    end

    return connection[:state] if connection

    nil
  end

  def self.index
    response = {
      items: connections[:custom].values.map do |connection|
        connection[:_key] = connection[:idempotency_key]
        connection
      end
    }

    response[:default] = connections[:default] if connections.key?(:default)
    response
  end

  def self.create(headers, body)
    updated_connections = connections

    body[:connection][:config][:name] = body[:connection][:config][:name].gsub('/', '-').to_slug.normalize.to_s

    if body[:connection][:config][:address] =~ /localhost/ || body[:connection][:config][:address] =~ /127.0.0.1/
      body[:connection][:config][:address] = body[:connection][:config][:address].gsub('localhost', '172.17.0.1')
      body[:connection][:config][:address] = body[:connection][:config][:address].gsub('127.0.0.1', '172.17.0.1')
    end

    if body[:connection][:config][:connect] =~ /localhost/ || body[:connection][:config][:connect] =~ /127.0.0.1/
      body[:connection][:config][:connect] = body[:connection][:config][:connect].gsub('localhost', '172.17.0.1')
      body[:connection][:config][:connect] = body[:connection][:config][:connect].gsub('127.0.0.1', '172.17.0.1')
    end

    if body[:connection][:config][:certificate] =~ /%\s*$/
      body[:connection][:config][:certificate] = body[:connection][:config][:certificate].sub(/%\s*$/, '')
    end

    if body[:connection][:config][:macaroon] =~ /%\s*$/
      body[:connection][:config][:macaroon] = body[:connection][:config][:macaroon].sub(/%\s*$/, '')
    end

    updated_connections[:custom][body[:connection][:config][:name]] = {
      created_at: Time.now,
      idempotency_key: headers['Idempotency-Key'],
      config: body[:connection][:config],
      state: nil
    }

    NitroxCore.badger.set('connections', updated_connections)

    { status: 201 }
  end

  def self.destroy(headers, params)
    updated_connections = connections

    updated_connections[:custom].delete(params['name'])

    Lighstorm::Connection.remove!(params['name'])

    NitroxCore.badger.set('connections', updated_connections)

    { status: 204 }
  end
end
