configure :development do
  set :database, 'sqlite3:weekly.db'
  set :show_exceptions, true
end

configure :production do
 db = URI.parse(ENV['DATABASE_URL'] || 'postgres:///ec2-54-204-38-16.compute-1.amazonaws.com/dps09k54dun45')

 ActiveRecord::Base.establish_connection(
   :adapter  => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
   :host     => db.host,
   :username => db.user,
   :password => db.password,
   :database => db.path[1..-1],
   :encoding => 'utf8'
 )
end
