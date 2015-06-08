require "sinatra"
require "sinatra/contrib"
require "pry"
require "pg"
require "redcarpet"

$db = PG.connect({dbname: 'wiki_db'})

module Wiki
	class Server < Sinatra::Base
		configure do 
			register Sinatra::Reloader
			set :sessions, true
		end


		def loggedIn?
			if session[:user_id].nil?
				redirect '/'
			end
		end

		$markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML, extensions = {})

		get '/' do
			erb :index
		end

		post '/users' do
			@id = $db.exec_params("INSERT INTO users (name, email, password) VALUES ($1, $2, $3) RETURNING id", [params[:name], params[:email], params[:password]]).first["id"]
			session[:user_id] = @id
			session[:user_name] = $db.exec_params("SELECT name FROM users WHERE id=$1", [@id]).first["name"]
			redirect '/'
		end

		post '/users/login' do
			@user = $db.exec_params("SELECT * FROM users WHERE email=$1 AND password=$2", [params[:email], params[:password]]).first
			if @user.nil?
				@message = "Failed login"
				redirect '/'
			else
				session[:user_id] = @user["id"]
				session[:user_name] = @user["name"]
				redirect '/'
			end
		end


		get '/users/logout' do
			session[:user_id] = nil
			session[:user_name] = nil
			redirect '/'
		end


		get '/search' do
			loggedIn?
			@search_tags = params[:tags].gsub(",", "").split(" ")
			@search_results = []
			@search_tags.each do |tag|
				@result_articles = $db.exec_params("SELECT id, title FROM articles WHERE $1 = ANY (tags)", [tag])
				@result_articles.each do |result|
					unless @search_results.include? [result["id"], result["title"]]
						@search_results.push([result["id"], result["title"]])
					end
				end
			end
			erb :search
		end



		get '/:article' do
			loggedIn?
			@article = $db.exec_params("SELECT * FROM articles, users WHERE articles.title=$1 AND articles.edited_by=users.id", [params[:article]]).first
			if @article.nil?
				erb :create
			else
				erb :article
			end
		end
		
		post '/:article' do
			@tags = params[:tags].gsub(",", "").split(" ")
			$db.exec_params("INSERT INTO articles (title, content, last_edited, edited_by, tags) VALUES ($1, $2, CURRENT_TIMESTAMP, $3, $4)", [params[:article], params[:content], session[:user_id], '{"' + @tags.join('", "') + '"}'])
			redirect '/' + params[:article]
		end
		
		patch '/:article' do
			$db.exec_params("UPDATE articles SET content = $1, last_edited = CURRENT_TIMESTAMP, edited_by = $2", [params[:content], session[:user_id]])
			redirect '/' + params[:article]
		end

		get '/:article/edit' do
			loggedIn?
			@article = $db.exec_params("SELECT * FROM articles, users WHERE articles.title=$1 AND articles.edited_by=users.id", [params[:article]]).first
			erb :create
		end


	end
end
