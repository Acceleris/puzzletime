require 'test_helper'

module Plannings
  class CustomListsControllerTest < ActionController::TestCase

    include CrudControllerTestHelper

    setup :login

    def test_new
      get :new, custom_list: { item_type: 'Employee' }
      assert_response :success
      assert_template 'new'
      assert entry.new_record?
      assert_equal 'Employee', entry.item_type
      assert_equal Employee, assigns(:available_items).klass
    end

    def test_create
      super
      assert_equal employees(:mark), entry.employee
    end

    private

    # Test object used in several tests.
    def test_entry
      custom_lists(:list_a)
    end

    # Attribute hash used in several tests.
    def test_entry_attrs
      { name: 'Happiness',
        item_type: 'Employee',
        item_ids: [6, 7, 8] }
    end
  end
end