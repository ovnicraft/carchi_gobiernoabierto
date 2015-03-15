module ActiveRecord
    module Validations
      class UniquenessValidator < ActiveModel::EachValidator # :nodoc:
        def build_relation(klass, table, attribute, value) #:nodoc:
          if reflection = klass.reflect_on_association(attribute)
            attribute = reflection.foreign_key
            value = value.attributes[reflection.primary_key_column.name] unless value.nil?
          end

          attribute_name = attribute.to_s

          # the attribute may be an aliased attribute
          if klass.attribute_aliases[attribute_name]
            attribute = klass.attribute_aliases[attribute_name]
            attribute_name = attribute.to_s
          end

          column = klass.columns_hash[attribute_name]
          value  = klass.connection.type_cast(value, column)
          # <tania@efaber.net> 
          # added  "&& !column.nil?" to fix error on uniqueness validation
          value  = value.to_s[0, column.limit] if value && !column.nil? && column.limit && column.text?

          if !options[:case_sensitive] && value && column.text?
            # will use SQL LOWER function before comparison, unless it detects a case insensitive collation
            klass.connection.case_insensitive_comparison(table, attribute, column, value)
          else
            value = klass.connection.case_sensitive_modifier(value) unless value.nil?
            table[attribute].eq(value)
          end
        end
      end
    end
end
