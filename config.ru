require 'sinatra'
require 'grape'
require 'redis'
require 'redis-namespace'

if ENV["REDISTOGO_URL"]
  uri = URI.parse(ENV["REDISTOGO_URL"])
  redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  redis =  Redis.new
end
REDIS = Redis::Namespace.new(:ucchusma, redis: redis)

class API < Grape::API
  format :json
  default_format :json

  helpers do
    def check_token!
      error!('Invalid Token.') unless params[:token] == ENV['TOKEN']
    end
  end

  namespace 'api/v1' do

    resource :info do
      params do
        requires :token, type: String
      end
      get do
        check_token!
        REDIS.hgetall :info
      end

      params do
        requires :token,   type: String
        requires :message, type: String
      end
      put do
        check_token!
        REDIS.hmset :info, :message, params[:message], :updated_at, Time.now
        true
      end

    end

    resources :rooms do
      params do
        requires :id, type: Integer
      end
      namespace ':id' do
        get do
          REDIS.hgetall params[:id]
        end

        params do
          requires :status,    type: String
          requires :token,     type: String
        end
        put do
          check_token!
          REDIS.hmset params[:id], :status, params[:status], :updated_at, Time.now
          true
        end
      end
    end
  end
end

class Web < Sinatra::Base
  get '/' do
    "It works!"
  end
end

run Rack::Cascade.new [API, Web]
