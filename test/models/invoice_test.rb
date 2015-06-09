require 'test_helper'

class InvoiceTest < ActiveSupport::TestCase

  test 'title with contract' do
    assert_equal 'Webauftritt gemäss Vertrag web1234', invoice.title
  end

  test 'period must be positive' do
    invoice.period_to = invoice.period_from
    assert_valid invoice
    invoice.period_to = invoice.period_to - 1.day
    assert_not_valid invoice, :period_to
  end

  test 'billing address must belong to order client' do
    invoice.billing_address = billing_addresses(:puzzle)
    assert_not_valid invoice, :billing_address_id
  end

  test 'generates invoice number' do
    i = invoice.dup
    i.reference = nil
    i.save!
    assert_equal 'STOPWEBD10002', i.reference
  end

  private

  def invoice
    invoices(:webauftritt_may)
  end

end

class InvoiceTransactionTest < ActiveSupport::TestCase

  self.use_transactional_fixtures = false

  test 'generates different parallel invoice numbers' do
    ActiveRecord::Base.clear_active_connections!
    10.times.collect do
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          invoices(:webauftritt_may).dup.save!
        end
      end
    end.each(&:join)

    assert_equal 11, clients(:swisstopo).last_invoice_number
    assert_equal 11, Invoice.pluck(:reference).uniq.size
  end

end