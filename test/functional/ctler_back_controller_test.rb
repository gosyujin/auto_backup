require File.expand_path(File.dirname(__FILE__) + '/../../test/test_helper')

class CtlerBackControllerTest < ActionController::TestCase
  def setup
    @request = ActionController::TestRequest.new
    @request.session[:user_id] = 3
    @request.env["HTTP_REFERER"] = '/'
    @response = ActionController::TestResponse.new

    @project = Project.find(2)
    #@project.enabled_modules << EnabledModule.new(:name => 'auto_backup')
    @project.save!
  end

  test "should get index" do
   get :index
  end
end
