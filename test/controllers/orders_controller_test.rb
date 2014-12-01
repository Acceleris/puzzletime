require 'test_helper'

class OrdersControllerTest < ActionController::TestCase

  setup :login

  test 'GET index sorted by order' do
    get :index, sort: 'order', status_id: ''
    assert_equal orders(:allgemein, :hitobito_demo, :puzzletime, :webauftritt), assigns(:orders)
  end

  test 'GET index sorted by kind' do
    get :index, sort: 'kind', status_id: ''
    assert_equal orders(:allgemein, :puzzletime, :hitobito_demo, :webauftritt), assigns(:orders)
  end

  test 'GET index sorted by department' do
    get :index, sort: 'department', status_id: ''
    assert_equal orders(:puzzletime, :webauftritt, :hitobito_demo, :allgemein), assigns(:orders)
  end

  test 'GET index sorted by responsible' do
    get :index, sort: 'responsible', status_id: ''
    assert_equal orders(:webauftritt, :allgemein, :hitobito_demo, :puzzletime), assigns(:orders)
  end

  test 'GET index sorted by status' do
    get :index, sort: 'status', status_id: ''
    assert_equal orders(:hitobito_demo, :puzzletime, :webauftritt, :allgemein), assigns(:orders)
  end

  test 'GET index with default filter for manager' do
    login_as(:mark)
    get :index
    assert_equal orders(:hitobito_demo, :puzzletime, :webauftritt), assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id },
                 session[:list_params]['/orders'])
  end

  test 'GET index with default filter for user' do
    login_as(:pascal)
    get :index
    assert_equal [orders(:hitobito_demo)], assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id,
                   'department_id' => departments(:devtwo).id },
                 session[:list_params]['/orders'])
  end

  test 'GET index with default filter for responsible' do
    login_as(:lucien)
    get :index
    assert_equal orders(:hitobito_demo, :puzzletime), assigns(:orders)
    assert_equal({ 'status_id' => order_statuses(:bearbeitung).id,
                   'responsible_id' => employees(:lucien).id },
                 session[:list_params]['/orders'])
  end

  test 'GET index filtered by department' do
    get :index, department_id: departments(:devone).id
    assert_equal orders(:puzzletime, :webauftritt), assigns(:orders)
  end

  test 'GET index filtered by status' do
    get :index, status_id: order_statuses(:bearbeitung).id
    assert_equal orders(:hitobito_demo, :puzzletime, :webauftritt), assigns(:orders)
  end

  test 'GET index filtered by kind' do
    get :index, kind_id: order_kinds(:projekt).id
    assert_equal orders(:hitobito_demo, :webauftritt), assigns(:orders)
  end

  test 'GET index filtered by status and kind' do
    get :index, status_id: order_statuses(:bearbeitung), kind_id: order_kinds(:mandat).id
    assert_equal [orders(:puzzletime)], assigns(:orders)
  end

  test 'GET index filtered by department, status and kind' do
    get :index, department_id: departments(:devtwo),
                status_id: order_statuses(:bearbeitung),
                kind_id: order_kinds(:mandat).id
    assert_equal [], assigns(:orders)
  end

  test 'GET show' do
    get :show, id: orders(:hitobito_demo).id
    assert_template 'show'
  end

  test 'GET cockpit' do
    get :cockpit, id: orders(:hitobito_demo).id
    assert_template 'cockpit'
  end

  test 'GET new presets some values' do
    get :new
    user = employees(:mark)
    order = assigns(:order)
    assert_equal user.department_id, order.department_id
    assert_equal user, order.responsible
  end

  test 'POST create sets values' do
    assert_difference('Order.count') do
      post :create, client_work_item_id: clients(:swisstopo).id,
                    order: {
                      work_item_attributes: {
                        name: 'New Order',
                        shortname: 'NEO'
                      },
                      department_id: departments(:devtwo).id,
                      responsible_id: employees(:pascal).id,
                      kind_id: order_kinds(:projekt).id,
                      status_id: order_statuses(:bearbeitung).id,
                      order_team_members_attributes: {
                          "0" => { employee_id: employees(:half_year_maria).id, comment: "rolle maria" },
                          "1" => { employee_id: employees(:next_year_pablo).id, comment: "rolle pablo"}
                      },
                      order_contacts_attributes: {
                          "0" => { contact_id: contacts(:swisstopo_1), comment: "funktion 1"},
                          "1" => { contact_id: contacts(:swisstopo_2), comment: "funktion 2"}
                      }
                    }
    end

    assert_redirected_to order_path(assigns(:order))

    item = WorkItem.where(name: 'New Order').first
    order = item.order
    assert_equal 'NEO', item.shortname
    assert_equal clients(:swisstopo).id, item.parent_id
    assert_equal departments(:devtwo).id, order.department_id
    assert_equal employees(:pascal).id, order.responsible_id
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id

    order_contacts = order.order_contacts.map {|oc| [oc.contact_id, oc.comment]}.sort
    assert_equal [[contacts(:swisstopo_1).id, "funktion 1"], [contacts(:swisstopo_2).id, "funktion 2"]].sort, order_contacts

    order_team_members = order.order_team_members.map {|otm| [otm.employee.id, otm.comment]}.sort
    assert_equal [[employees(:half_year_maria).id, "rolle maria"], [employees(:next_year_pablo).id, "rolle pablo"]].sort, order_team_members
  end

  test 'PATCH update sets values' do
    order = orders(:puzzletime)
    patch :update, id: order.id,
                   order: {
                     work_item_attributes: {
                       name: 'New Order',
                       shortname: 'NEO'
                     },
                     department_id: departments(:devtwo).id,
                     responsible_id: employees(:pascal).id,
                     kind_id: order_kinds(:projekt).id,
                     status_id: order_statuses(:bearbeitung).id,
                     order_team_members_attributes: {
                         "0" => { employee_id: employees(:half_year_maria).id, comment: "rolle maria" },
                         "1" => { employee_id: employees(:next_year_pablo).id, comment: "rolle pablo"}
                     },
                     order_contacts_attributes: {
                         "0" => { contact_id: contacts(:puzzle_rava), comment: "funktion 1"},
                         "1" => { contact_id: contacts(:puzzle_hauswart), comment: "funktion 2"}
                     }
                   }

    assert_redirected_to order_path(order)

    order.reload
    item = order.work_item
    assert_equal 'New Order', item.name
    assert_equal 'NEO', item.shortname
    assert_equal clients(:puzzle).id, item.parent_id
    assert_equal departments(:devtwo).id, order.department_id
    assert_equal employees(:pascal).id, order.responsible_id
    assert_equal order_statuses(:bearbeitung).id, order.status_id
    assert_equal order_kinds(:projekt).id, order.kind_id

    order_contacts = order.order_contacts.map {|oc| [oc.contact_id, oc.comment]}.sort
    assert_equal [[contacts(:puzzle_rava).id, "funktion 1"], [contacts(:puzzle_hauswart).id, "funktion 2"]].sort, order_contacts

    order_team_members = order.order_team_members.map {|otm| [otm.employee.id, otm.comment]}.sort
    assert_equal [[employees(:half_year_maria).id, "rolle maria"], [employees(:next_year_pablo).id, "rolle pablo"]].sort, order_team_members
  end
end
