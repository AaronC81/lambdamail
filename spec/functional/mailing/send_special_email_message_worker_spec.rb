describe LambdaMail::Mailing::SendSpecialEmailMessageWorker do
  it 'sends mail' do
    message = LambdaMail::Model::SpecialEmailMessage.new(
      subject: 'Foo',
      body: 'Bar',
      recipient: 'joe.bloggs@example.com'
    )
    message.save

    described_class.new.perform(message.id, false)

    deliveries = Mail::TestMailer.deliveries
    expect(deliveries.length).to be 1

    delivery = deliveries.first
    expect(delivery.to).to eq ['joe.bloggs@example.com']
    expect(delivery.subject).to eq 'Foo'
    expect(delivery.body).to eq 'Bar'
  end
end
