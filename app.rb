require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'

enable :sessions

def connect_to_db
    db = SQLite3::Database.new("db/slpws23.db")
    db.results_as_hash = true
    return db
end

#ska visa samma som titles
get('/') do
    slim(:start)
end

get('/titles/') do
    db = connect_to_db
    result = db.execute("SELECT * FROM titles")
    slim(:"titles/index", locals:{titles:result})
end

get('/titles/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_groups = db.execute("SELECT * FROM groups WHERE TitleId = ?", id)
    result_title = db.execute("SELECT TitleName FROM titles WHERE TitleID = ?", id).first
    slim(:"titles/show", locals:{groups:result_groups, title:result_title})
end

get('/groups/') do
    db = connect_to_db
    result = db.execute("SELECT * FROM groups")
    slim(:"groups/index", locals:{groups:result})
end

get('/groups/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result = db.execute("SELECT * FROM groups WHERE GroupID = ?", id).first
    slim(:"groups/show", locals:{groups:result})

end

