class AccountsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  # include AuthenticatedSystem

  def send_password
    @account = Account.scoped_by_email(params[:email]).first
    if @account
      if @account.generate_random_password!
        AccountMailer.deliver_password(@account)
        flash[:notice] = "Thanks! We are sending you a new password!"      
        redirect_to new_session_path
      else
        flash[:error] = "We couldnt setup a new password for #{params[:email]}!"
        redirect_to forgot_password_path
      end
    else
      flash[:error] = "We couldnt find your account by #{params[:email]}!"
      redirect_to forgot_password_path
    end
  end

  def account_index
    if params[:account_login].blank?
      if logged_in?
        redirect_to account_index_path current_account.login
      else
        redirect_to home_path
      end
    else
      @account = account_from_path

      if @account
        @notifications = Notification.paginate :conditions => "publisher_id = #{@account.id} OR publisher_id IN (#{@account.friend_ids})" , :page => params[:page], :per_page => 10
      else
        flash[:error] = "Account #{params[:account_login]} couldn't be found!"
        respond_to do |format|
          format.html { redirect_to home_path }
          format.atom
        end
      end
    end
  end

  # render new.rhtml
  def new
    @account = Account.new
  end

  def edit
    @account = Account.find(params[:id])
  end

  def update
    @account = Account.find(params[:id])

    params[:account].delete :avatar if params[:account][:avatar].nil?
    params[:account].delete :password if params[:account][:password].blank?
    params[:account].delete :password_confirmation if params[:account][:password_confirmation].blank?

    if @account.update_attributes(params[:account])
      flash[:notice] = 'Account was successfully updated.'
      redirect_to account_index_path(@account.login)
    else
      flash[:error] = "Couldn't update Account!"
      render :action => 'edit'
    end
  end

  def create
    logout_keeping_session!
    @account = Account.new(params[:account])
    success = @account && @account.save
    if success && @account.errors.empty?
      redirect_back_or_default('/')
      flash[:notice] = "Thanks for signing up!  We're sending you an email with your activation code."
    else
      flash[:error]  = "We couldn't set up that account, sorry.  Please try again, or contact an admin (link is above)."
      render :action => 'new'
    end
  end

  def activate
    logout_keeping_session!
    account = Account.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
    when (!params[:activation_code].blank?) && account && !account.active?
      account.activate!
      flash[:notice] = "Signup complete! Please sign in to continue."
      redirect_to '/login'
    when params[:activation_code].blank?
      flash[:error] = "The activation code was missing.  Please follow the URL from your email."
      redirect_back_or_default('/')
    else
      flash[:error]  = "We couldn't find a account with that activation code -- check your email? Or maybe you've already activated -- try signing in."
      redirect_back_or_default('/')
    end
  end
end

