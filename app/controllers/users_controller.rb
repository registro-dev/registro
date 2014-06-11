class UsersController < ApplicationController
	include UsersHelper
	
	before_filter :need_login, :only => [ :user, :edit, :update, :new, :create ]
	before_filter :validate_id, :only => [ :user, :edit, :update ]
	
	# the login form & the login action
	def login
		# if the user is alread logged in, redirect him somewhere
		if session[:token]
			redirect_to root_path
			return
		end
		# if the request is the form, show it!
		if request.get?
			# render...
		# if the request is a login from username & password
		elsif request.post?
			# check the username and the password presence
			if params[:login] && params[:login][:username] && params[:login][:password]
				# check if they are correct
				@user = Credential.check params[:login]
				unless @user
					flash.now[:error] = "Username/Password errati"
					LoginFail.bad_password request.remote_ip, params[:login]
				else
					# login the user and generate a new token
					token = @user.get_new_token
					session[:token] = token
					session[:user_id] = @user.id
					flash.now[:info] = "Login effettuato"
					redirect_to root_path
				end
			else
				head :bad_request
			end
		end
	end
	
	def logout
		# if the user wasn't logged it
		unless session[:token]
			flash[:warning] = "L'utente non era connesso"
			redirect_to login_path
		else
			session[:token] = nil
			session[:user_id] = nil
			flash.now[:info] = "Utente disconnesso"
			redirect_to login_path
		end
	end
	
	def user
		begin
			me = User.find session[:user_id]
			target = User.find params[:id]
			
		    @user = get_user_info me, target
		rescue ActiveRecord::RecordNotFound
    		flash.now[:error] = "Utente non trovato"
		end
	end
	
	def edit
		# TODO aggingere cotrollo sull'accesso e sui permessi
		begin
		    @user = User.find params[:id]
		rescue ActiveRecord::RecordNotFound
    		flash.now[:error] = "Utente non trovato"
		end
		
	end
	
	def update
		# TODO aggiungere controllo sull'accesso e sui permessi
	
		if not params[:user]
			render inline: "<h1>Bad Request</h1>", status: :bad_request
			return
		end
		
		p = params[:user]
		begin
			user = User.find params[:id]
		rescue ActiveRecord::RecordNotFound
			flash.now[:error] = "Utente non trovato"
			redirect_to me_path
			return
		end
		
		# TODO aggiungere controlli!
		user.name = p[:name] 		if p[:name]
		user.surname = p[:surname] 	if p[:surname]
		
		begin
			status = user.save			
		rescue
			status = false
		end
		
		if not status
			flash[:error] = "Impossibile salvare le informazioni"
			redirect_to_edit user
			return
		end
		
		flash[:info] = "Informazioni salvate"
		redirect_to_edit user
	end
	
	def new
		# TODO aggiungere controllo dei permessi
	end
	
	def create
		# TODO aggiungere controllo dei permessi
		if not params[:user]
		    render inline: "<h1>Bad Request</h1>", status: :bad_request
			return
		end
		
		p = params[:user]
		
		# check if all required params are present
		required_params = [ 'username', 'password', 'name', 'surname' ]
		required_params.each do |key|
		    if not p[key]
		        flash.now[:error] = "Parametro #{key} non specificato"
		        render inline: "<h1>Bad Request</h1>", status: :bad_request
			    return
		    end
		end		
		
		user = nil
		
		begin
		    user = 			User.create create_user_params 		    
		    credential = 	Credential.create create_credential_params(user)
		    redirect_to user_path user
		rescue Exception => e
		    flash[:error] = "Impossibile creare l'utente"		    
		    redirect_to root_path
		end
	end
	
	# ==================
	     protected
	# ==================
		
	# check if the user is logged in
	def need_login
		redirect_to login_path unless session[:token]
	end
	
	# check if the id parameter is valid
	def validate_id
		params[:id] = session[:user_id] if params[:id] == nil
		unless params[:id] && params[:id].to_i > 0
			flash[:error] = "Identificativo non valido"
			redirect_to root_path
			return false
		end
		return true
	end
	
	# redirect to the correct edit page
	def redirect_to_edit user
		if user.id == session[:user_id]
			redirect_to own_edit_path
		else
			redirect_to edit_path user
		end
		return true
	end
	
	
	# ==============
	     private
	# ==============
	
	def create_user_params params = params
		params = { name: params[:user][:name], surname: params[:user][:surname] }
	end
	
	def create_credential_params user, params = params
		params = { 
			username: params[:user][:username], 
			password: params[:user][:password],
			user_id: user.id
		}
	end
end
