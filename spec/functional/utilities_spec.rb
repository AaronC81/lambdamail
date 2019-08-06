describe LambdaMail::Utilities do
  describe '.generate_token' do
    it 'results in 20 character tokens' do
      expect(described_class.generate_token.length).to be 20
    end

    it 'is random' do
      expect(described_class.generate_token).not_to eq described_class.generate_token
    end
  end

  describe '.deep_keys_to_sym' do
    it 'functions correctly for hashes and arrays' do
      expect(described_class.deep_keys_to_sym({
        'a': 'foo',
        'b': {
          'c': [
            {
              'd': 'bar',
              'e': 'baz'
            }
          ]
        }
      })).to eq({
        a: 'foo',
        b: {
          c: [
            {
              d: 'bar',
              e: 'baz'
            }
          ]
        }
      })
    end
  end
end