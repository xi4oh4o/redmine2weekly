require 'json'
require 'erb'
require 'time'
require 'yaml'
require 'faraday'
require 'sinatra'
require 'sinatra/activerecord'
require 'sinatra/flash'
require 'sinatra/redirect_with_flash'
require './mail'
require './environments'

CONF = YAML.load(File.open('config.yml'))

enable :sessions
set :session_secret, "#{::CONF['Secret']}"

I18n.enforce_available_locales = true

helpers do

  def encrypt(password)
    Digest::SHA256.hexdigest(password)
  end

  def parseJson(url)
    response = Faraday.get(url)
    response_hash = JSON.parse(response.body)
    return response_hash
  end

  def simpleTime(time)
    unless time
      return '待完成'
    end
    t = Time.parse(time)
    return t.strftime("%Y-%m-%d")
  end

  def takeFivedayRange
    d = Date.today
    five_days_range = [ (d - 5).to_s, d ]
    return five_days_range
  end

  def getWeekAgo(key)
    url = "#{::CONF['Redmine']['url']}/issues.json?assigned_to_id=" +
    "me&status_id=*&start_date=" +
    "%3E%3C#{takeFivedayRange[0]}%7C#{takeFivedayRange[1]}&key=#{key}"

    parseJson(url)
  end

  def solveState(state)

    case state
    when 1
      status_info = '<span style="color: red">待解决</span>'
    when 2
      status_info = '<span style="color: red">进行中</span>'
    when 3
      status_info = '<span style="color: green">已解决</span>'
    when 4
      status_info = '<span style="color: blue">反馈</span>'
    when 5
      status_info = '<span style="color: green">已完成</span>'
    end

    return status_info
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
    if @auth and !@auth.key.to_s.empty? and !@auth.email.to_s.empty?
      @html = getWeekAgo(@auth.key)
      # email_body = erb :mail, layout: false, locals: {fields: @html}
      # sendWeekPost('xi4oh4o@lonlife.net', 'postmaster@etude.mailgun.org', 'Hello', email_body)
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
      @auth.key = params[:auth]['key'] if params[:auth]['key']
      @auth.email = params[:auth]['email'] if params[:auth]['email']
      if @auth.save
        redirect '/', :notice => 'Congrats! 记录已保存'
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


get '/user/:name/remove_emails' do
  if session['username'] == params['name']
    @auth = Auth.find_by(username: params['name'])
    if @auth
      @auth.email = ''
      if @auth.save
        redirect '/', :notice => 'Congrats! 您已成功移除Email.'
      end
    end
  end
end
