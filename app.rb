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

@conf = YAML.load(File.open('config.yml'))

enable :sessions
set :session_secret, "#{@conf['Secret']}"

I18n.enforce_available_locales = true

helpers do

  def encrypt(password)
    Digest::SHA256.hexdigest(password)
  end

end

class Auth < ActiveRecord::Base
  validates :username, uniqueness: true
  validates :username, :password, presence: true
end

# Login Authentication

get('/login') do
  if session['username']
    redirect '/'
  end
  erb :"user/login"
end

post '/login' do
  if params[:auth]
    @user = Auth.find_by(username: params[:auth]['username'])
    if @user
      if ( params[:auth]['username'] == @user.username &&
        encrypt(params[:auth]['password']) == @user.password )
        session['username'] = params[:auth]['username']
        redirect '/', :notice => '您已成功登录!'
      else
        redirect '/login', :error => ['授权验证失败.']
      end
    end
    redirect '/login', :error => ['当前用户不存在.']
  end
end

# User registration

get ('/user/create') do
  if session['username']
    redirect '/'
  end

  erb :"user/create"
end

post '/user/create' do
  params[:auth]['password'] =
    encrypt(params[:auth]['password'])
  @auth = Auth.new(params[:auth])
  if @auth.save
    session['username'] = params[:auth]['username']
    redirect '/', :notice => 'Congrats! 您已成功注册.'
  else
    redirect '/user/create', :error => @auth.errors.full_messages
  end
end

# Dashboard

get ('/') do
  if session['username']
    @auth = Auth.find_by(username: session['username'])
    if @auth
      time = @auth.updated_at + 3600
      if time < Time.now
      end
    end
  else
    redirect '/login', :notice => '请先登录!'
  end

  erb :index
end

post ('/') do
  if session['username']
    @auth = Auth.find_by(username: session['username'])
    if @auth
      @auth.key = params[:auth]['key']
      if @auth.save
        redirect '/', :notice => 'Congrats! 您已成功保存Redmine Key.'
      end
    end
  end
end

get '/user/:name/remove_key' do
  if session['username'] == params['name']
    @auth = Auth.find_by(username: params['name'])
    if @auth
      @auth.key = ''
      if @auth.save
        redirect '/', :notice => 'Congrats! 您已成功移除Redmine Key.'
      end
    end
  end
end
