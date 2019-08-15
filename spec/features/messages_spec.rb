describe 'the messages page', type: :feature do
  before :all do
    LambdaMail::Model::ComposedEmailMessage.create(message_subject: 'Foo').save
    LambdaMail::Model::ComposedEmailMessage.create.save
  end

  describe 'list view' do
    it 'lists all messages' do
      visit '/admin/messages'
      expect(page).to have_content('Foo')
      expect(page).to have_content('No subject')
    end
  end

  describe 'single view' do
    it 'pre-populates the subject line' do
      visit '/admin/messages/1'
      expect(page).to have_field('Subject', with: 'Foo')

      visit '/admin/messages/2'
      expect(find_field('Subject').value).to be_nil
    end

    it 'allows the subject to be updated' do
      visit '/admin/messages/1'
      fill_in 'Subject', with: 'Bar'
      click_button 'Save'
      expect(page).to have_field('Subject', with: 'Bar')
      expect(LambdaMail::Model::ComposedEmailMessage.get(1).message_subject).to eq 'Bar'
    end
  end
end
