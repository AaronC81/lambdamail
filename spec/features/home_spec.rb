describe 'the home page', type: :feature do
  it 'can be visited' do
    visit '/'
    expect(page.status_code).to be 200
  end
end