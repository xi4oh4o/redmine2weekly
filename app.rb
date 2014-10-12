require 'json'
require 'erb'
require 'time'
require 'yaml'
require 'faraday'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require './environments'

I18n.enforce_available_locales = true

enable :sessions

helpers do
  def getConf
    @conf = YAML.load(File.open('config.yml'))
  end

  def encrypt(password)
    Digest::SHA256.hexdigest(password)
  end
end

class Auth < ActiveRecord::Base
  validates :username, uniqueness: true
  validates :username, :password, presence: true
end
