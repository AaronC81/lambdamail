require 'timeout'

describe 'the subscribe page', type: :feature do
  it 'allows a user to send a subscription confirmation email to themselves' do
    visit '/subscribe'
    fill_in 'Name', with: 'Joe Bloggs'
    fill_in 'Email', with: 'joe@bloggs.biz'
    click_button 'Subscribe'
    expect(page).to have_content 'Confirm your email address'

    workers!

    deliveries = Mail::TestMailer.deliveries
    expect(deliveries.length).to be 1

    delivery = deliveries.first
    expect(delivery.to).to eq ['joe@bloggs.biz']
    expect(delivery.subject.downcase).to include 'confirm'
  end
end