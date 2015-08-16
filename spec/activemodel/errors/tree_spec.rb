require 'spec_helper'

describe ActiveModel::Errors::Tree do
  let(:klass) do
    Object.const_set('AnonymousRecord', Class.new(ActiveRecord::Base) do
      self.table_name = 'test'

      has_one :one, class_name: 'AnonymousRecord', foreign_key: :id, autosave: true
      has_many :many, class_name: 'AnonymousRecord', foreign_key: :id, autosave: true

      attr_accessor :field, :another_field, :error
      validate do
        if @error
          errors.add :field, :invalid
          errors.add :field, :blank
        end
      end
    end)
  end
  after { Object.send(:remove_const, 'AnonymousRecord') }

  let(:record) do
    klass.new(
      error: true, # self
      one: klass.new(
        error: true, # one (0)
        one: klass.new(
          error: true, # one -> one (00)
          one: klass.new(error: true), # one -> one -> one (000)
          many: [klass.new, klass.new(error: true), klass.new(error: true)], # one -> one -> many (001)
        ),
        many: [
          klass.new,
          klass.new(
            error: true, # one -> many (01)
            one: klass.new(error: true), # one -> many -> one (010)
            many: [klass.new, klass.new(error: true), klass.new(error: true)], # one -> many -> many (011)
          ),
          klass.new(error: true),
        ]
      ),
      many: [
        klass.new,
        klass.new(
          error: true, # many (1)
          one: klass.new(
            error: true, # many -> one (10)
            one: klass.new(error: true), # many -> one -> one (100)
            many: [klass.new, klass.new(error: true), klass.new(error: true)], # many -> one -> many (101)
          ),
          many: [
            klass.new,
            klass.new(
              error: true, # many -> many (1)
              one: klass.new(error: true), # many -> many -> one (110)
              many: [klass.new, klass.new(error: true), klass.new(error: true)], # many -> many -> many (111)
            ),
            klass.new(error: true),
          ],
        ),
        klass.new(error: true),
      ],
    ).tap(&:validate)
  end

  describe "#messages" do
    subject { record.errors.tree.messages }
    it "is correct" do
      should eq(
        "field" => ["is invalid", "can't be blank"],
        "one" => {
          "field" => ["is invalid", "can't be blank"],
          "one" => {
            "field" => ["is invalid", "can't be blank"],
            "one" => {"field" => ["is invalid", "can't be blank"]},
            "many" => [{}, {"field" => ["is invalid", "can't be blank"]}, {"field" => ["is invalid", "can't be blank"]}]
          },
          "many" => [
            {},
            {
              "field" => ["is invalid", "can't be blank"],
              "one" => {"field" => ["is invalid", "can't be blank"]},
              "many" => [{}, {"field" => ["is invalid", "can't be blank"]}, {"field" => ["is invalid", "can't be blank"]}]
            },
            {"field" => ["is invalid", "can't be blank"]}
          ]
        },
        "many" => [
          {},
          {
            "field" => ["is invalid", "can't be blank"],
            "one" => {
              "field" => ["is invalid", "can't be blank"],
              "one" => {"field" => ["is invalid", "can't be blank"]},
              "many" => [{}, {"field" => ["is invalid", "can't be blank"]}, {"field" => ["is invalid", "can't be blank"]}]
            },
            "many" => [
              {},
              {
                "field" => ["is invalid", "can't be blank"],
                "one" => {"field" => ["is invalid", "can't be blank"]},
                "many" => [{}, {"field" => ["is invalid", "can't be blank"]}, {"field" => ["is invalid", "can't be blank"]}]
              },
              {"field" => ["is invalid", "can't be blank"]}
            ]
          },
          {"field" => ["is invalid", "can't be blank"]}
        ]
      )
    end
  end

  describe "#details" do
    subject { record.errors.tree.details }
    it "is correct" do
      should eq(
        "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
        "one" => {
          "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
          "one" => {
            "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
            "one" => {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]},
            "many" => [{}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}]
          },
          "many" => [
            {},
            {
              "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
              "one" => {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]},
              "many" => [{}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}]
            },
            {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}
          ]
        },
        "many" => [
          {},
          {
            "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
            "one" => {
              "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
              "one" => {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]},
              "many" => [{}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}]
            },
            "many" => [
              {},
              {
                "field" => [{ 'error' => :invalid }, { 'error' => :blank }],
                "one" => {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]},
                "many" => [{}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}, {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}]
              },
              {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}
            ]
          },
          {"field" => [{ 'error' => :invalid }, { 'error' => :blank }]}
        ]
      )
    end
  end

  context "update" do
    before { record.errors.add "another_field", :present }

    describe "#messages" do
      subject { record.errors.tree.messages[:another_field] }
      it("is correct") { should eq ["must be blank"] }
    end

    describe "#details" do
      subject { record.errors.tree.details[:another_field] }
      it("is correct") { should eq ['error' => :present] }
    end
  end
end
