require "sinatra"
require "sinatra/contrib"
require "pry"
require "pg"

$db = PG.connect({dbname: 'wiki_db'})

module Wiki
	class Server < Sinatra::Base
		configure do 
			register Sinatra::Reloader
		end

		$current_user = 1

		get '/' do
			erb :index
		end

		get '/:article' do
			@article = $db.exec_params("SELECT * FROM articles, users WHERE articles.title=$1 AND articles.edited_by=users.id", [params[:article]]).first
			if @article.nil?
				erb :create
			else
				erb :article
			end
		end

		get '/:article/edit' do
			@article = $db.exec_params("SELECT * FROM articles, users WHERE articles.title=$1 AND articles.edited_by=users.id", [params[:article]]).first
			erb :create
		end

		post '/:article' do
			$db.exec_params("INSERT INTO articles (title, content, last_edited, edited_by) VALUES ($1, $2, CURRENT_TIMESTAMP, $3)", [params[:article], params[:content], $current_user])
			redirect '/' + params[:article]
		end

		patch '/:article' do
			$db.exec_params("UPDATE articles SET content = $1, last_edited = CURRENT_TIMESTAMP, edited_by = $2", [params[:content], $current_user])
			redirect '/' + params[:article]
		end


	end
end
