describe 'the admin namespace', type: :feature do
  it 'handles 404s gracefully' do
    visit '/admin/this-url-does-not-exist'
    expect(page.status_code).to be 404
    expect(page).to have_content 'Item not found'

    visit '/admin/messages/9999'
    expect(page.status_code).to be 404
    expect(page).to have_content 'Item not found'
  end
end