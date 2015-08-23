#!/usr/bin/ruby
# Code for analyzing 18,000+ class names

require 'lingua/stemmer'
load    'klassextant_export.rb'

class Klassextant
  attr_reader :base, :analytes
  attr_accessor :debug

  include KlassextantExport

  def initialize(filename="FBclasses.txt", opt={})
    @known_stems = opt[:known_stems] || ['ADT','AS','FB','GL','HPP','ID','MN','MQTT','NS','NUX','PYM','NFX','OTD','QP','SSO','UI','URL','UFI']
    debug = opt[:debug] || false

    klass_load(filename)
  end

  def analytes
    @analytes ||= @base.map do |c|
      Hash[
        :prefix, (c.match(/^_?([A-Z]*)[A-Z][a-z]/) || [])[1],
        :class_parts, c.sub(/#{$1}/,'').split(/([A-Z]{1,})/).reject(&:empty?).each_slice(2).map(&:join)
      ]
    end
  end

  def analyte_tree
    @analyte_tree ||= analytes.reduce({}) do |baseh, an|
      baseh[an[:prefix]] ||= {}
      baseh[an[:prefix]][:class_parts] ||= []
      baseh[an[:prefix]][:class_parts] << an[:class_parts]
      baseh
    end
  end

  def parts
    @parts ||= analytes.reduce([]) do |parts, a|
      parts += a[:class_parts]  
    end.sort.uniq - analyte_tree.keys
  end

  def part_stems
    @part_stems ||= parts.
      reject{|p| p.scan(/^[a-z]/).any? }.
      map{|p| Lingua.stemmer p }.
      reject{|stem| stem.sub(/[a-z0-9]/,'').size == 1 }.
      push(*@known_stems). # handcrafting
      sort
  end

  def stem_tree
    @stem_tree ||= parts.
      group_by do |p|
        part_stems.select do |stem|
          p.start_with? stem 
        end.first || p
      end
  end

  def stem_counts
    unless @stem_counts
      @stem_counts = {}
      analyte_tree.values.each do |k|
        k[:class_parts].each do |cp|
          cp.each_with_index do |part, idx|
            @stem_counts[part_stem_lookup[part]] ||= {:positions => []}
            @stem_counts[part_stem_lookup[part]][:positions].push idx 
          end
        end
      end

      @stem_counts.keys.each {|stem|
        @stem_counts[stem][:clusters]  = @stem_counts[stem][:positions].group_by{|w| w }.reduce({}) {|se, g| se[g.first] = g.last.size; se }
        @stem_counts[stem][:total_use] = @stem_counts[stem][:clusters].collect(&:last).inject(&:+)
        @stem_counts[stem][:avg_pos]   = @stem_counts[stem][:total_use]/@stem_counts[stem][:positions].size.to_f 
        @stem_counts[stem][:median]    = @stem_counts[stem][:clusters].max_by(&:last).first
      }  
    end
    @stem_counts
  end


  def part_stem_lookup
    @part_stem_lookup = stem_tree.reduce({}) do |lookup, stem, parts|
      lookup.merge( stem.last.reduce({}) do |parts, part|
        parts[part] = stem.first
        parts 
      end)
    end
  end

  private

  def klass_load(filename)
    @base = File.readlines(filename).
      map(&:strip).
      map{|c| c.sub('.h','').gsub(/[_-]/,'') }
  end

end


