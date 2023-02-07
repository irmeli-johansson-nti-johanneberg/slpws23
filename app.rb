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

    puts result_posts

    slim(:"groups/show", locals:{groups:result_group, posts:result_posts})

end


get('/posts/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_post = db.execute("SELECT posts.post_id, posts.owning_user_id, users.user_name, posts.post_name, posts.post_content FROM posts INNER JOIN users ON posts.owning_user_id = users.user_id WHERE posts.group_id = ?", id).first

    slim(:"posts/show", locals:{post:result_post})
end
