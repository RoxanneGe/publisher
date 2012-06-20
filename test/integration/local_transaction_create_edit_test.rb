#encoding: utf-8
require 'integration_test_helper'

class LocalTransactionCreateEditTest < ActionDispatch::IntegrationTest
  setup do
    LocalService.create(lgsl_code: 1, providing_tier: %w{county unitary})
    LocalAuthority.create(snac: 'ABCDE')

    @artefact = FactoryGirl.create(:artefact,
        slug: "hedgehog-topiary",
        kind: "local_transaction",
        name: "Foo bar",
        owning_app: "publisher",
    )

    setup_users
  end

  test "creating a local transaction sends the right emails" do


    email_count_before_start = ActionMailer::Base.deliveries.count

    visit "/admin/publications/#{@artefact.id}"

    fill_in 'Lgsl code', :with => '1'
    click_button 'Create Local transaction'
    assert page.has_content? "Viewing “Foo bar” Edition 1"

    assert_equal email_count_before_start + 1, ActionMailer::Base.deliveries.count
    assert_match /Created Local transaction: "Foo bar"/, ActionMailer::Base.deliveries.last.subject
  end

  test "creating a local transaction with a bad LGSL code displays an appropriate error" do

    visit "/admin/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in "Lgsl code", :with => "2"
    click_on 'Create Local transaction edition'

    assert page.has_content? "Lgsl code 2 not recognised"
  end


  test "creating a local transaction from panopticon requests an LGSL code" do

    visit "/admin/publications/#{@artefact.id}"
    assert page.has_content? "We need a bit more information to create your local transaction."

    fill_in 'Lgsl code', :with => '1'
    click_button 'Create Local transaction'
    assert page.has_content? "Viewing “Foo bar” Edition 1"
  end

  test "editing a local transaction has the LGSL and LGIL fields" do
    edition = FactoryGirl.create(:local_transaction_edition, :panopticon_id => @artefact.id, :slug => @artefact.slug,
                                 :title => "Foo transaction", :lgsl_code => 1)

    visit "/admin/editions/#{edition.to_param}"

    assert page.has_content? "Viewing “Foo transaction” Edition 1"

    assert page.has_field?("LGSL code", :with => "1")
    assert page.has_field?("LGIL override", :with => "")

    fill_in "LGIL override", :with => '7'

    click_button "Save"

    assert page.has_content? "Local transaction edition was successfully updated."

    e = LocalTransactionEdition.find(edition.id)
    assert_equal 7, e.lgil_override

    # Ensure it gets set to nil when clearing field
    fill_in "LGIL override", :with => ''
    click_button "Save"

    assert page.has_content? "Local transaction edition was successfully updated."

    e = LocalTransactionEdition.find(edition.id)
    assert_equal nil, e.lgil_override
  end
end