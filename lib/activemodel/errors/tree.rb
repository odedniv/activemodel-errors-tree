require "active_model/errors"
require "active_support/hash_with_indifferent_access"

module ActiveModel
  class Errors
    class Tree
      def initialize(base, errors)
        @base   = base
        @errors = errors
      end

      ATTRIBUTE_SEPARATOR = "."

      def messages
        @messages ||= method_tree(:messages)
      end

      def details
        @details ||= method_tree(:details)
      end

      private

      def method_tree(method)
        result = ActiveSupport::HashWithIndifferentAccess.new
        @errors.keys.each do |original_attribute|
          attribute, sub_attribute = original_attribute.to_s.split(ATTRIBUTE_SEPARATOR, 2) # we really only care about the first one
          if sub_attribute.nil?
            result[attribute] = @errors.send(method)[original_attribute]
          else
            sub_base = @base.send(attribute)
            result[attribute] = sub_base.respond_to?(:map) ? sub_base.map { |r| r.errors.tree.send(method) } : sub_base.errors.tree.send(method)
          end
        end
        result
      end
    end

    def tree
      @tree ||= Tree.new(@base, self)
    end

    alias_method :add_without_reset_tree, :add
    def add(*args)
      @tree = nil
      add_without_reset_tree(*args)
    end

    alias_method :delete_without_reset_tree, :delete
    def delete(*args)
      @tree = nil
      delete_without_reset_tree(*args)
    end

    alias_method :clear_without_reset_tree, :clear
    def clear(*args)
      @tree = nil
      clear_without_reset_tree(*args)
    end
  end
end
