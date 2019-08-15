describe 'the recipients page', type: :feature, js: true do
  before :all do
    LambdaMail::Model::Recipient.create(name: 'Joe Bloggs', email_address: 'jb@example.com').save
    LambdaMail::Model::Recipient.create(name: 'Anne Example', email_address: 'anne@test.com').save
  end

  it 'lists all recipients' do
    visit '/admin/recipients'
    expect(page).to have_content 'Joe Bloggs'
    expect(page).to have_content 'jb@example.com'
    expect(page).to have_content 'Anne Example'
    expect(page).to have_content 'anne@test.com'
  end

  it 'allows recipients to be added' do
    visit '/admin/recipients'
    fill_in 'Name', with: 'Test Person'
    fill_in 'Email', with: 'test@person.org'
    click_button 'Create'
    expect(page).to have_content 'Test Person'
    expect(page).to have_content 'test@person.org'
  end

  it 'allows recipients to be deleted' do
    visit '/admin/recipients'
    find('tr', text: /Anne Example/).click_link 'Delete'
    expect(page).to have_content 'Joe Bloggs'
    expect(page).to have_content 'jb@example.com'
    expect(page).not_to have_content 'Anne Example'
    expect(page).not_to have_content 'anne@test.com'
  end
end