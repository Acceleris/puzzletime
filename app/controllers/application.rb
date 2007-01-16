# (c) Puzzle itc, Berne
# Diplomarbeit 2149, Xavier Hayoz

# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include CalendarHelper

  before_filter :set_charset

  def set_charset
    @headers["Content-Type"] = "text/html; charset=utf-8" 
  end
  
  #Filter for check if user is logged in or not
  def authenticate
    @user = session[:user]
    unless @user
      flash[:notice] = 'Please log in'
      redirect_to(:controller => 'login', :action => 'login' )
    end
  end 
  
  def authorize
    authenticate
    unless @user.management
      flash[:notice] = 'You are not authorized to view this page'
      redirect_to(:controller => 'login', :action => 'login' )
    end
  end  

  def rescue_action_in_public(exception)
    case exception
      when ActiveRecord::RecordNotFound, ::ActionController::UnknownAction
        render(:file => "#{RAILS_ROOT}/public/404.html",
               :status => "404 Not Found")
      else
        render(:file => "#{RAILS_ROOT}/public/500.html",
               :status => "500 Error")
        SystemNotifier.deliver_exception_notification(self, request, exception)
    end                    
  end
  
end

