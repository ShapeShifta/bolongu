class ThingsController < ApplicationController

  def add
    @thing = Thing.find(params[:id])
    current_account.things << @thing
    flash[:notice] = "#{@thing.name} was added to your things."
    redirect_to :back
  end
  
  def remove
    @thing = Thing.find(params[:id])
    current_account.things.delete @thing
    flash[:notice] = "#{@thing.name} was removed from your things."
    redirect_to :back
  end
  
  # GET /things
  # GET /things.xml
  def index
    if params[:account_id]
      @account = Account.find(params[:account_id])
      @show = params[:show]
      case @show
      when 'account'
        search_account
      when 'all'
        search_all
      when 'network'
        search_network
      else
        if logged_in? and @account == current_account
          @show = 'all'
          search_all
        else
          @show = 'account'
          search_account
        end
      end
    else
      @things = Thing.paginate :page => params[:page], :per_page => 10
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @things }
    end
  end

  # GET /things/1
  # GET /things/1.xml
  def show
    @thing = Thing.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @thing }
    end
  end

  # GET /things/new
  # GET /things/new.xml
  def new
    @thing = Thing.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @thing }
    end
  end

  # GET /things/1/edit
  def edit
    @thing = Thing.find(params[:id])
  end

  # POST /things
  # POST /things.xml
  def create
    @thing = Thing.new(params[:thing])
    @thing.author = current_account
    @thing.should_tweet = params[:twitter]
    respond_to do |format|
      if @thing.save
        current_account.things << @thing
        
        flash[:notice] = 'Thing was successfully created.'
        format.html { redirect_to @thing }
        format.xml  { render :xml => @thing, :status => :created, :location => @thing }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @thing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /things/1
  # PUT /things/1.xml
  def update
    @thing = Thing.find(params[:id])

    params[:thing].delete :photo if params[:thing][:photo].nil?

    respond_to do |format|
      if @thing.update_attributes(params[:thing])
        flash[:notice] = "#{@thing.name} was updated."
        format.html { redirect_to(@thing) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @thing.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /things/1
  # DELETE /things/1.xml
  def destroy
    @thing = Thing.find(params[:id])
    @thing.destroy
    flash[:notice] = "#{@thing.name} was deleted."
    respond_to do |format|
      format.html { redirect_to(things_url) }
      format.xml  { head :ok }
    end
  end
  
  private
  
  def search_account
    @things = @account.things.paginate :page => params[:page], :per_page => 10
  end
  
  def search_all
    if @account.friend_ids.empty?
      search_account
    else
      @things = Thing.paginate :conditions => "author_id = #{@account.id} OR (author_id IN (#{@account.friend_ids_as_string}) AND (blog_private = 'false' OR blog_private = 'f'))" , :page => params[:page], :per_page => 10   
    end
  end
  
  def search_network
    unless @account.friend_ids.empty?
      @things = Thing.paginate :conditions => "author_id IN (#{@account.friend_ids_as_string}) AND (blog_private = 'false' OR blog_private = 'f')" , :page => params[:page], :per_page => 10
    else
      @things = Thing.paginate :conditions => ['id=?', 0], :page => params[:page], :per_page => 10
    end
  end
end
