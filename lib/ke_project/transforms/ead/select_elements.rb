# frozen_string_literal: true

module KeProject
  module Transforms
    module Ead
      # This sample transformation shows how to use XML documents
      # in `kiba-extend` projects. It selects specific elements,
      # prints their contents to stdout for learning/debugging
      # purposes, and transforms one attribute to demonstrate the
      # basic patterns. Confirm functionality by checking the
      # output file, which should have the same filename as the
      # input, but:
      #   - no explicit namespaces (they were stripped when the
      #     data source was set up becuase we passed `remove_namespaces`
      #     to the XmlDir constructor in the registry entry for
      #     `orig__ead`); and
      #   - @audience attribute(s) should read 'internal'
      class SelectElements
        def process(doc)
          title = doc.at_xpath("//titleproper")&.text
          unitid = doc.at_xpath("//unitid")&.text
          puts "#{doc.url}: #{title} (#{unitid})"

          doc.xpath('//*[@audience="external"]').each do |node|
            node["audience"] = "internal"
          end

          doc
        end
      end
    end
  end
end
