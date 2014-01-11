require 'sinatra'
require 'grape'
require 'redis'
require 'redis-namespace'

REDIS = Redis::Namespace.new(:ucchusma, redis: Redis.new)

class API < Grape::API
  format :json
  default_format :json

  namespace 'api/v1' do
    resources :rooms do
      params do
        requires :id, type: Integer
      end
      namespace ':id' do
        get do
          REDIS.hgetall(params[:id])
        end

        params do
          requires :status,    type: String
          requires :token,     type: String
        end
        put do
          error!('Invalid Token.') unless params[:token] == ENV['TOKEN']
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