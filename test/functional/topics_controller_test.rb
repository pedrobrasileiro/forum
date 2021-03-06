require File.dirname(__FILE__) + '/../test_helper'
require 'topics_controller'

# Re-raise errors caught by the controller.
class TopicsController; def rescue_action(e) raise e end; end

class TopicsControllerTest < Test::Unit::TestCase
  all_fixtures

  def setup
    @controller = TopicsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  def test_should_get_index
    get :index, :forum_id => 1
    assert_redirected_to forum_path(1)
  end

  def test_should_show_topic_as_rss
    get :show, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :format => 'rss'
    assert_response :success
  end

  def test_should_get_new
    login_as :aaron
    get :new, :forum_id => 1
    assert_response :success
  end

  def test_sticky_protected_from_non_admin
    login_as :sam
    post :create, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :sticky => "1", :body => 'foo' }
    assert assigns(:topic)
    assert ! assigns(:topic).sticky?
  end
    
  def test_should_allow_admin_to_sticky
    login_as :aaron
    post :create, :forum_id => forums(:rails).id, :topic => { :title => 'blah2', :sticky => "1", :body => 'foo' }
    assert assigns(:topic).sticky?
  end

  def test_should_create_topic
    counts = lambda { [Topic.count, Post.count, forums(:rails).topics_count, forums(:rails).posts_count,  users(:aaron).posts_count] }
    old = counts.call
    
    login_as :aaron
    post :create, :forum_id => forums(:rails).id, :topic => { :title => 'blah', :body => 'foo' }
    assert assigns(:topic)
    assert assigns(:post)
    [forums(:rails), users(:aaron)].each &:reload
  
    assert_equal old.collect { |n| n + 1}, counts.call
  end
  
  def test_should_delete_topic
    counts = lambda { [Post.count, forums(:rails).topics_count, forums(:rails).posts_count] }
    old = counts.call
    
    login_as :aaron
    delete :destroy, :forum_id => forums(:rails).id, :id => topics(:ponies).id
    [forums(:rails), users(:aaron)].each &:reload

    assert_equal old.collect { |n| n - 1}, counts.call
  end

  def test_should_allow_moderator_to_delete_topic
    assert_difference Topic, :count, -1 do
      login_as :sam
      delete :destroy, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    end
  end

  def test_should_update_views_for_show
    views=topics(:pdi).views
    get :show, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    assert_response :success
    assert_equal views+1, topics(:pdi).reload.views
  end

  def test_should_update_views_for_show_except_topic_author
    login_as :aaron
    views=topics(:pdi).views
    get :show, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    assert_response :success
    assert_equal views, topics(:pdi).reload.views
  end

  def test_should_show_topic
    get :show, :forum_id => forums(:rails).id, :id => topics(:pdi).id
    assert_response :success
    assert_equal topics(:pdi), assigns(:topic)
    assert_models_equal [posts(:pdi), posts(:pdi_reply), posts(:pdi_rebuttal)], assigns(:posts)
  end

  def test_should_show_other_post
    get :show, :forum_id => forums(:rails).id, :id => topics(:ponies).id
    assert_response :success
    assert_equal topics(:ponies), assigns(:topic)
    assert_models_equal [posts(:ponies)], assigns(:posts)
  end

  def test_should_get_edit
    login_as :aaron
    get :edit, :forum_id => 1, :id => 1
    assert_response :success
  end
  
  def test_should_update_own_post
    login_as :sam
    put :update, :forum_id => forums(:rails).id, :id => topics(:ponies).id, :topic => { }
    assert_redirected_to topic_path(forums(:rails), assigns(:topic))
  end

  def test_should_not_update_user_id_of_own_post
    login_as :sam
    put :update, :forum_id => forums(:rails).id, :id => topics(:ponies).id, :topic => { :user_id => 32 }
    assert_redirected_to topic_path(forums(:rails), assigns(:topic))
    assert_equal users(:sam).id, posts(:ponies).reload.user_id
  end

  def test_should_not_update_other_post
    login_as :sam
    put :update, :forum_id => forums(:comics).id, :id => topics(:galactus).id, :topic => { }
    assert_redirected_to login_path
  end

  def test_should_update_other_post_as_moderator
    login_as :sam
    put :update, :forum_id => forums(:rails).id, :id => topics(:pdi).id, :topic => { }
    assert_redirected_to topic_path(forums(:rails), assigns(:topic))
  end

  def test_should_update_other_post_as_admin
    login_as :aaron
    put :update, :forum_id => forums(:rails).id, :id => topics(:ponies), :topic => { }
    assert_redirected_to topic_path(forums(:rails), assigns(:topic))
  end
end
