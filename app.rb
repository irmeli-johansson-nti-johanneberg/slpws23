require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

get('/') do
    slim(:start)
end


get('/groups/') do
    db = SQLite3::Database.new("db/slpws23.db")
    db.results_as_hash = true
    result = db.execute("SELECT * FROM groups")
    slim(:"groups/index", locals:{groups:result})
  
  end