require 'factory_girl_rails'
include FactoryGirl::Syntax::Methods
require 'test_helper'

class NeighborhoodsControllerTest < ActionController::TestCase
  setup do
    @neighborhood = create(:neighborhood)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:neighborhoods)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create neighborhood" do
    assert_difference('Neighborhood.count') do
      post :create, neighborhood: { borough: @neighborhood.borough, name: @neighborhood.name }
    end

    assert_redirected_to neighborhood_path(assigns(:neighborhood))
  end

  test "should show neighborhood" do
    get :show, id: @neighborhood
    assert_response :success
  end

  test "should get edit" do
    get :edit, id: @neighborhood
    assert_response :success
  end

  test "should update neighborhood" do
    patch :update, id: @neighborhood, neighborhood: { borough: @neighborhood.borough, name: @neighborhood.name }
    assert_redirected_to neighborhood_path(assigns(:neighborhood))
  end

  test "should destroy neighborhood" do
    assert_difference('Neighborhood.count', -1) do
      delete :destroy, id: @neighborhood
    end

    assert_redirected_to neighborhoods_path
  end
end
