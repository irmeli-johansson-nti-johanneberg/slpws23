require 'sinatra'
require 'sinatra/reloader'
require 'slim'
require 'sqlite3'
require 'bcrypt'
require 'date'

enable :sessions

def connect_to_db
    db = SQLite3::Database.new("db/slpws23.db")
    db.results_as_hash = true
    return db
end

#ska visa samma som sections
get('/') do
    slim(:start)
end

get('/sections/') do
    db = connect_to_db
    result = db.execute("SELECT * FROM sections")
    slim(:"sections/index", locals:{sections:result})
end

get('/sections/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_groups = db.execute("SELECT * FROM groups WHERE section_id = ?", id)
    result_section = db.execute("SELECT section_name FROM sections WHERE section_id = ?", id).first
    slim(:"sections/show", locals:{groups:result_groups, section:result_section})
end

get('/groups/') do
    db = connect_to_db
    result = db.execute("SELECT * FROM groups")
    slim(:"groups/index", locals:{groups:result})
end

get('/groups/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_group = db.execute("SELECT * FROM groups WHERE group_id = ?", id).first
    result_posts = db.execute("SELECT posts.post_id, posts.owning_user_id, users.user_name, posts.post_name FROM posts INNER JOIN users ON posts.owning_user_id = users.user_id WHERE posts.group_id = ?", id)

    session[:current_group_id] = id

    slim(:"groups/show", locals:{groups:result_group, posts:result_posts})

end


get('/posts/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_post = db.execute("SELECT posts.post_id, posts.owning_user_id, users.user_name, posts.post_name, posts.post_content FROM posts INNER JOIN users ON posts.owning_user_id = users.user_id WHERE posts.post_id = ?", id).first
    result_comments = db.execute("SELECT comments.comment_id, comments.owning_user_id, users.user_name, comments.comment_content FROM comments INNER JOIN users ON comments.owning_user_id = users.user_id WHERE comments.post_id = ?", id)

    slim(:"posts/show", locals:{post:result_post, comments:result_comments})
end

post("/posts") do
    new_post_name = params[:new_post_name]
    new_post_content = params[:new_post_content]
    group_id = session[:current_group_id].to_i
    user_id = session[:user_id].to_i

    current_time = DateTime.now
    new_post_date = current_time.strftime "%Y-%m-%d %H:%M:%S"

    db = SQLite3::Database.new("db/slpws23.db")
    result = db.execute("INSERT INTO posts (group_id, owning_user_id, post_name, post_content, post_date) VALUES (?, ?, ?, ?, ?)", group_id, user_id, new_post_name, new_post_content, new_post_date)

    redirect("/groups/#{group_id}")
end

get('/login/') do
    slim(:"users/index")
end

post("/login") do
    # username = params[:username]
    # password = params[:password]
    username = "test_user"

    db = connect_to_db
    result = db.execute("SELECT * FROM users WHERE user_name = ?", username).first
    password_digest = result["password_digest"]
    id = result["user_id"]

    
#   if BCrypt::Password.new(password_digest) == password
#     session[:wrongpw] = false
#     session[:id] = id
#     session[:username] = username
#     redirect('/todos/')
#   else
#     session[:wrongpw] = true
#     redirect('/login/')
#   end

    session[:user_id] = id
    session[:user_name] = username

    redirect("/sections/")
end

