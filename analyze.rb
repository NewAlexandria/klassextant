#!/usr/bin/ruby
# Code for analyzing 18,000+ class names

require 'lingua/stemmer'

class Klassextant
  attr_reader :base, :analytes

  def initialize(filename="FBclasses.txt", opt={})
    @known_stems = opt[:known_stems] || ['ADT','AS','FB','GL','HPP','ID','MN','MQTT','NS','NUX','PYM','NFX','OTD','QP','SSO','UI','URL','UFI']
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
    #flatten_identity_stems(@stem_tree)
  end

  def stem_positions
    stem_tree.inject(stems_empty) do |counts, stem, parts|
      analyte_tree.values.
      counts[stem] += fb.base.map{|klass| klass.index( stem_tree.keys.first ) }.compact
      counts
    end

    stem_tree.keys.inject(stems_empty) do |counts, stem|
      counts[stem] += fb.base.map{|klass| klass.index( stem_tree.keys.first ) }.compact
      counts
    end
  end

  def part_stem_lookup
    @part_stem_lookup = stem_tree.reduce({}) do |lookup, stem, parts|
      lookup.merge( stem.last.reduce({}) do |parts, part|
        parts[part] = stem.first
        parts 
      end)
    end
  end

  def part_counts
    @ns_parts_counts ||= analytes.reduce({}) do |ag,a|
      ag[a[:prefix]] ||= []
      ag[a[:prefix]] << a[:class_parts].size
      ag 
    end
  end

  def parts_empty
    Hash[ parts.zip(Array.new(parts.size, [])) ]
  end

  def parts_positions 
    @parts_positions ||= analytes.reduce( parts_empty ) do |pos, a|
      a[:class_parts].each_with_index do |part, idx|
        pos[part] << idx
      end
      pos
    end
  end

# parts_positions['Component'].reduce(:+)/parts_positions['Component'].size.to_f
# parts_positions['Component'].group_by(&:itself).values.max_by(&:size).first

  private

  def klass_load(filename)
    @base = File.readlines(filename).
      map(&:strip).
      map{|c| c.sub('.h','').gsub(/[_-]/,'') }
  end

  def flatten_identity_stems( tree )
    working_tree = {}
    tree.each { |k,v| (v.size == 1) ? working_tree[v] = nil : working_tree[k] = v }
    tree = working_tree
  end

end


