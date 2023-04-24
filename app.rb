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

post('/groups') do
    new_group_name = params[:new_group_name]
    new_group_description = params[:new_group_description]
    new_group_tags = params[:new_group_tags].split(", ")
    section_id = params[:new_group_section].to_i
    new_group_mode = params[:new_group_mode]
    user_id = session[:user_id].to_i

    if user_id != 0
        
        db = SQLite3::Database.new("db/slpws23.db")
        name_unique = db.execute("SELECT COUNT(group_name) FROM groups WHERE group_name = ?", new_group_name).first.first.to_i
        if name_unique == 0
            current_time = DateTime.now
            new_group_date = current_time.strftime "%Y-%m-%d"

            db.execute("INSERT INTO groups (owning_user_id, group_name, group_description, section_id, group_date, group_mode) VALUES (?, ?, ?, ?, ?, ?)", user_id, new_group_name, new_group_description, section_id, new_group_date, new_group_mode)
            group_id = db.execute("SELECT group_id FROM groups WHERE group_name = ?", new_group_name).first.first.to_i

            new_group_tags.each do |group_tag|
                tag_exist = db.execute("SELECT COUNT(tag_name) FROM tags WHERE tag_name = ?", group_tag).first.first.to_i
                if tag_exist == 0
                    db.execute("INSERT INTO tags (tag_name) VALUES (?)", group_tag)
                end
                tag_id = db.execute("SELECT tag_id FROM tags WHERE tag_name = ?", group_tag).first.first.to_i
                db.execute("INSERT INTO group_tag_rel (group_id, tag_id) VALUES (?,?)", group_id, tag_id)
            end
            redirect("/groups/#{group_id}")
        else
            redirect("/groups/new")
            #Namn inte unikt, redan upptaget :(
        end
    else
        redirect("/groups/new")
    end

end

get('/groups/new') do
    db = connect_to_db
    result = db.execute("SELECT * FROM sections")
    slim(:"groups/new", locals:{sections:result})
end

get('/groups/') do
    db = connect_to_db
    result = db.execute("SELECT * FROM groups")
    slim(:"groups/index", locals:{groups:result})
end

get('/groups/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_group = db.execute("SELECT groups.*, users.user_name FROM groups INNER JOIN users ON groups.owning_user_id = users.user_id WHERE groups.group_id = ?", id).first
    result_posts = db.execute("SELECT posts.*, users.user_name FROM posts INNER JOIN users ON posts.owning_user_id = users.user_id WHERE posts.group_id = ?", id)
    result_group_tags = db.execute("SELECT group_tag_rel.tag_id, tags.tag_name FROM group_tag_rel INNER JOIN tags ON group_tag_rel.tag_id = tags.tag_id WHERE group_tag_rel.group_id = ?", id)
    
    session[:current_group_id] = id

    slim(:"groups/show", locals:{group:result_group, posts:result_posts, group_tags:result_group_tags})

end

post("/posts") do
    new_post_name = params[:new_post_name]
    new_post_content = params[:new_post_content]
    group_id = session[:current_group_id].to_i
    user_id = session[:user_id].to_i

    if user_id != 0
        current_time = DateTime.now
        new_post_date = current_time.strftime "%Y-%m-%d %H:%M"

        db = SQLite3::Database.new("db/slpws23.db")
        db.execute("INSERT INTO posts (group_id, owning_user_id, post_name, post_content, post_date) VALUES (?, ?, ?, ?, ?)", group_id, user_id, new_post_name, new_post_content, new_post_date)
    end
    redirect("/groups/#{group_id}")
end

get('/posts/:id') do
    id = params[:id].to_i
    db = connect_to_db
    result_post = db.execute("SELECT posts.*, users.user_name FROM posts INNER JOIN users ON posts.owning_user_id = users.user_id WHERE posts.post_id = ?", id).first
    result_group = db.execute("SELECT owning_user_id FROM groups WHERE group_id = ?", result_post['group_id'].to_i).first
    result_comments = db.execute("SELECT comments.*, users.user_name FROM comments INNER JOIN users ON comments.owning_user_id = users.user_id WHERE comments.post_id = ?", id)
    session[:current_post_id] = id
    slim(:"posts/show", locals:{posts:result_post, comments:result_comments, group:result_group})
end

get("/posts/:id/edit") do
    id = params[:id].to_i
    db = connect_to_db
    result = db.execute("SELECT * FROM posts WHERE post_id = ?", id).first
    slim(:"posts/edit", locals:{post:result})
end

post("/posts/:id/update") do
    post_id = params[:id].to_i
    user_id = session[:user_id].to_i
    edit_post_name = params["edit_post_name"]
    edit_post_content = params["edit_post_content"]
    db = SQLite3::Database.new("db/slpws23.db")
    post_owner_id = db.execute("SELECT owning_user_id FROM posts WHERE post_id = ?", post_id).first.first
    
    if post_owner_id == user_id
        db.execute("UPDATE posts SET (post_name, post_content) = (?,?) WHERE post_id = ?", edit_post_name, edit_post_content, post_id)
        redirect("/posts/#{post_id}")
    else
        #Något felmeddelande
        redirect("/posts/#{post_id}")
    end
end

post("/comments") do
    new_comment_content = params[:new_comment_content]
    post_id = session[:current_post_id].to_i
    user_id = session[:user_id].to_i

    if user_id != 0
        current_time = DateTime.now
        new_comment_date = current_time.strftime "%Y-%m-%d %H:%M"

        db = SQLite3::Database.new("db/slpws23.db")
        db.execute("INSERT INTO comments (post_id, owning_user_id, comment_content, comment_date) VALUES (?, ?, ?, ?)", post_id, user_id, new_comment_content, new_comment_date)
    end
    redirect("/posts/#{post_id}")
end

get("/comments/:id/edit") do
    id = params[:id].to_i
    db = connect_to_db
    result = db.execute("SELECT * FROM comments WHERE comment_id = ?", id).first
    slim(:"comments/edit", locals:{comment:result})
end

post("/comments/:id/update") do
    comment_id = params[:id].to_i
    user_id = session[:user_id].to_i
    edit_comment_content = params["edit_comment_content"]
    db = SQLite3::Database.new("db/slpws23.db")
    comment_owner_id, post_id = db.execute("SELECT owning_user_id, post_id FROM comments WHERE comment_id = ?", comment_id).first
    
    if comment_owner_id == user_id
        db.execute("UPDATE comments SET comment_content = ? WHERE comment_id = ?", edit_comment_content, comment_id)
        redirect("/posts/#{post_id}")
    else
        #Något felmeddelande
        redirect("/posts/#{post_id}")
    end
end

get("/users/:id") do
    user_id = params[:id].to_i

    db = connect_to_db
    result_user = db.execute("SELECT * FROM users WHERE user_id = ?", user_id).first
    result_posts = db.execute("SELECT * FROM posts WHERE owning_user_id = ?", user_id)
    result_comments = db.execute("SELECT comments.*, posts.post_id, posts.post_name FROM comments INNER JOIN posts ON comments.post_id = posts.post_id WHERE comments.owning_user_id = ?", user_id)

    slim(:"users/show", locals:{user:result_user, posts:result_posts, comments:result_comments})
end

post("/posts/:id/delete") do
    id = params[:id].to_i
    user_id = session[:user_id].to_i

    db = SQLite3::Database.new("db/slpws23.db")
    group_id, post_owner_id = db.execute("SELECT group_id, owning_user_id FROM posts WHERE post_id = ?", id).first
    group_owner_id = db.execute("SELECT owning_user_id FROM groups WHERE group_id = ?", group_id).first.first

    if post_owner_id == user_id || group_owner_id == user_id
        db.execute("DELETE FROM posts WHERE post_id = ?", id)
        db.execute("DELETE FROM comments WHERE post_id = ?", id)
        redirect("/groups/#{group_id}")
    else
        #Något felmeddelande ska visas på sidan
        redirect("/groups/#{group_id}")
    end
end

post("/comments/:id/delete") do
    id = params[:id].to_i
    post_id = session[:current_post_id].to_i
    db = SQLite3::Database.new("db/slpws23.db")
    db.execute("DELETE FROM comments WHERE comment_id = ?", id)
    redirect("/posts/#{post_id}")

    #lägg till validering rätt användare som deletar ( ska också kunna vara group admin)
end

get('/login/') do
    slim(:"users/index")
end

get('/register/') do
    slim(:"users/new")
end

post('/register') do
    session[:error_reg_unik] = false
    session[:error_reg_password] = false

    user_name = params[:user_name]
    password = params[:password]
    password_confirm = params[:password_confirm]

    current_time = DateTime.now
    new_user_date = current_time.strftime "%Y-%m-%d"
  
    db = SQLite3::Database.new("db/slpws23.db")
    result = db.execute("SELECT COUNT(user_name) FROM users WHERE user_name = ?", user_name).first.first

    if result == 0
        if password == password_confirm
            # Använd flash istället!!!!!
            session[:error_reg_unik] = false
            session[:error_reg_password] = false
            password_digest = BCrypt::Password.create(password)
            db = SQLite3::Database.new("db/slpws23.db")
            db.execute("INSERT INTO users (user_name, password_digest, user_date) VALUES (?,?,?)", user_name, password_digest, new_user_date)
            session[:user_id] = db.execute("SELECT user_id FROM users WHERE user_name = ?", user_name).first.first.to_i
            redirect('/sections/')
        else
            #felhanterign
            # Använd flash istället!!!!!
            session[:error_reg_password] = true
            redirect('/register/')
        end
    else
        session[:error_reg_unik] = true
        redirect('/register/')
    end
end

post('/login') do
    user_name = params[:user_name]
    password = params[:password]

    db = connect_to_db
    result = db.execute("SELECT * FROM users WHERE user_name = ?", user_name).first

    if result != nil
        if BCrypt::Password.new(result['password_digest']) == password
            # Använd flash istället!!!!!
            session[:error_log_in] = false
            session[:user_id] = result['user_id']
            redirect('/sections/')
        else
            # Använd flash istället!!!!!
            session[:error_log_in] = true
            redirect('/login/')
        end
    else
        # Använd flash istället!!!!!
        session[:error_log_in] = true
        redirect('/login/')
    end
end

get("/logout/") do
    slim(:"users/index")
end

post("/logout") do
    session.destroy
    redirect('/sections/')
end

