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
    result_group = db.execute("SELECT * FROM groups WHERE GroupID = ?", id).first
    result_posts = db.execute("SELECT posts.PostID, posts.UserId, users.UserName, posts.PostName FROM posts INNER JOIN users ON posts.UserId = users.UserID WHERE posts.GroupId = ?", id)

    slim(:"groups/show", locals:{groups:result_group, posts:result_posts})

end


get('/posts/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_post = db.execute("SELECT posts.PostID, posts.UserId, users.UserName, posts.PostName, posts.PostContent FROM posts INNER JOIN users ON posts.UserId = users.UserID WHERE posts.GroupId = ?", id).first

    slim(:"posts/show", locals:{post:result_post})
end
