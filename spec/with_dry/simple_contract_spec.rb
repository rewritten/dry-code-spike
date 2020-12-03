# frozen_string_literal: true

require 'csv'
require 'json'
require 'rack/utils'
require 'with_dry/simple_contract'

RSpec.describe WithDry::SimpleContract do
  subject { contract.call(input) }

  let(:contract) { described_class.new }
  let(:input) do |ex|
    case ex.metadata
      in {input: input} then input
      in {json: json} then JSON.parse(json)
      in {query: query} then Rack::Utils.parse_nested_query(query)
      in {csv: csv} then CSV.parse(csv, headers: true).first.to_h
    end
  end

  shared_examples '⛔️ validation' do
    it { is_expected.not_to be_success }

    if metadata[:errors]
      describe 'errors' do
        subject { super().errors(full: true).map(&:to_s) }

        it { |ex| is_expected.to(contain_exactly(*ex.metadata[:errors])) }
      end
    end
  end

  shared_examples '✅ validation' do
    it { is_expected.to be_success }
  end

  context 'with invalid data' do
    context 'name too short',
            input: { name: 'Foo', email: 'foo@bar.com' },
            errors: 'name size cannot be less than 5' do
      include_examples '⛔️ validation'
    end

    context 'email invalid',
            input: { name: 'FooBar', email: 'foo-without-at-sign' },
            errors: 'email is in invalid format' do
      include_examples '⛔️ validation'
    end

    context 'business rule validation',
            input: { name: 'FooBar', email: 'bazquz@quz.com' },
            errors: 'name seems not legit' do
      include_examples '⛔️ validation'
    end

    context 'all issues',
            input: { name: 'Foo', email: 'foo-without-at-sign' },
            errors: ['name size cannot be less than 5', 'email is in invalid format'] do
      include_examples '⛔️ validation'
    end

    context 'optional field passed',
            input: { name: 'FooBar', email: 'foobar@example.com', age: 9 },
            errors: 'age must be greater than 10' do
      include_examples '⛔️ validation'
    end

    context 'optional field unfilled',
            input: { name: 'FooBar', email: 'foobar@example.com', fingers: nil },
            errors: 'fingers must be filled' do
      include_examples '⛔️ validation'
    end

    context 'unfilled fields in query string',
            query: 'name=FooBar&email=foobar@example.com&fingers=',
            errors: 'fingers must be filled' do
      include_examples '⛔️ validation'
    end
  end

  context 'with valid data' do
    describe 'data formats' do
      context 'with plain data', input: { name: 'FooBar', email: 'foobar@example.com' } do
        include_examples '✅ validation'
      end

      context 'with string data', input: { 'name' => 'FooBar', 'email' => 'foobar@example.com' } do
        include_examples '✅ validation'
      end

      context 'with JSON data', json: '{"name":"FooBar","email":"foobar@example.com"}' do
        include_examples '✅ validation'
      end

      context 'with form-encoded data', query: 'name=FooBar&email=foobar@example.com&age=11&fingers=7' do
        include_examples '✅ validation'
      end

      context 'with CSV data', csv: <<~CSV do
        name,email,age,fingers
        FooBar,foobar@example.com,11,7
      CSV
        include_examples '✅ validation'

        it { expect(subject.to_h).to include(age: 11, fingers: 7) }
      end
    end

    context 'with an optional field left empty', query: 'name=FooBar&email=foobar@example.com&age=&fingers=7' do
      include_examples '✅ validation'

      it { expect(subject.to_h).to include(age: nil, fingers: 7) }
    end

    describe 'protection against symbol-based DOS attacks',
             input: { 'name' => 'FooBar', 'email' => 'foobar@example.com',
                      'some_very_long_denial_of_service' => 'PWNED' } do
      it 'does not allow to PWN the system' do
        expect(subject.to_h).to eq(name: 'FooBar', email: 'foobar@example.com')
        expect(Symbol.all_symbols.grep(/some_very_long_denial_of_service/)).to be_empty
      end
    end
  end
end
