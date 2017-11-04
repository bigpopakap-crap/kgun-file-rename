#!/usr/bin/env ruby
require 'csv'

class Name
  attr_reader :last
  attr_reader :first
  attr_reader :middle

  def initialize(last:, first:, middle: nil)
    @last = last
    @first = first
    @middle = middle
  end

  def self.format_s
    "Last, First Middle"
  end

  def to_s
    "#{last}, #{first} #{middle}"
  end

  def to_file_name
    if middle
      "#{last}_#{first}_#{middle}"
    else
      "#{last}_#{first}"
    end
  end

  def match_score(str)
    has_full_last = str.include?(last)
    has_full_first = str.include?(first)
    has_full_middle = middle && middle.length > 1 && str.include?(middle)

    (
      (has_full_last   ? 1 : 0) * 10 +
      (has_full_first  ? 1 : 0) * 8 +
      (has_full_middle ? 1 : 0) * 5
    )
  end
end

class NameDirectory
  attr_reader :names
  def initialize(names)
    @names = names
  end

  def find_match(file_name)
    matches = names.select { |n| n.match_score(file_name) > 1 }
    matches = matches.sort_by { |n| n.match_score(file_name) }.reverse

    if matches.length >= 2
      puts "#{file_name} matches multiple names: #{matches.map(&:to_s)}"
    end

    if matches.length == 1
      matches.first
    else
      nil
    end
  end
end

class NameParser
  def initialize(name_file)
    @name_file = name_file
  end

  def parse
    names = CSV.read(@name_file)
               .map do |row|
                 Name.new(
                    last: row[0]&.strip,
                    first: row[1]&.strip,
                    middle: row[2]&.strip
                 )
               end
    NameDirectory.new(names)
  end
end

class FileNameChange
  attr_reader :old_name
  attr_reader :new_name
  def initialize(old_name, new_name = nil)
    @old_name = old_name
    @new_name = new_name ? new_name : old_name
  end

  def to_s
    "#{old_name} => #{new_name}"
  end

  def update(updated_new_name)
    FileNameChange.new(old_name, updated_new_name)
  end
end

module FileOperations
  def self.strip_id(file_name_change)
    on_file_name_only(file_name_change) do |file_name|
      file_name.slice((file_name.index('_')+1)..-1)
    end
  end

  def self.clean_name(file_name_change, name_directory)
    on_file_name_only(file_name_change) do |file_name|
      name_match = name_directory.find_match(file_name)

      if name_match
        name_match.to_file_name
      else
        file_name
      end
    end
  end

  def self.append_type(file_name_change, dir_name)
    type = File.basename(dir_name)

    on_file_name_only(file_name_change) do |file_name|
      file_name + "_#{type}"
    end
  end

  private

  def self.on_file_name_only(file_name_change, &block)
    full_name = file_name_change.new_name

    dir_name = File.dirname(full_name)
    # TODO how should I handle multiple file extensions
    ext_name = File.extname(full_name)
    file_name = File.basename(full_name, ext_name)

    updated_new_name = yield file_name
    full_updated_new_name = File.join(dir_name, updated_new_name + ext_name)

    file_name_change.update(full_updated_new_name)
  end
end

class InputDir
  attr_reader :dir_name
  def initialize(dir_name)
    @dir_name = dir_name
  end

  def file_names
    Dir[File.join(dir_name, '*')]
  end

  def num_files
    file_names.length
  end

  def to_s
    "#{dir_name} (#{num_files} files)"
  end
end

module Main
  def self.run
    name_parser = NameParser.new('./names.csv')
    name_dir = name_parser.parse

    puts '== NAMES ====================== VERIFY THIS'
    puts Name.format_s
    puts '-----------'
    puts name_dir.names
    puts

    input_dir_name = './input'
    input_dirs = Dir.glob(File.join(input_dir_name, '*'))
                    .map { |dir_name| InputDir.new(dir_name) }

    puts '== INPUT DIRECTORIES ========== VERIFY THIS'
    puts input_dirs
    puts

    output_dir = './output'
    if !File.directory? output_dir
      Dir.mkdir output_dir
    end

    puts('== OUTPUT DIRECTORY =========== ' + (output_dir ? 'GOOD' : 'BAD!'))
    puts output_dir
    puts

    strip_id_changes = input_dirs
                            .map { |i_dir| i_dir.file_names }
                            .flatten
                            .map { |f| FileNameChange.new(f) }
                            .map { |c| FileOperations.strip_id(c) }

    puts '== FILES THAT MATCH MULTIPLE NAMES (MAYBE) ====== VERIFY THIS'
    name_lookup_changes = strip_id_changes
                            .map { |c| FileOperations.clean_name(c, name_dir) }
    puts

    unchanged_files = strip_id_changes
                    .zip(name_lookup_changes)
                    .map { |before, after| [before.new_name, after.new_name] }
                    .select { |before, after| before == after }
                    .map { |before, after| after }

    puts('== NO NAME MATCH FOR ========= ' + (unchanged_files.length ? 'GOOD! NO MANUAL WORK' : 'NEEDS MANUAL WORK'))
    puts(unchanged_files.length ? unchanged_files : 'none - all files matched!')
    puts

    name_lookup_results = name_lookup_changes.map { |c| c.new_name }
    name_collisions = name_lookup_results - name_lookup_results.uniq

    puts('== NAME COLLISIONS ===== ' + (name_collisions.length ? 'GOOD! NO COLLISIONS' : 'BAD!'))
    puts(name_collisions.length ? name_collisions : 'none - that is good!')
    puts

    all_changes = name_lookup_changes
                      .map { |c| FileOperations.append_type(c, File.dirname(c.old_name)) }
                      .map { |c| c.update(File.basename(c.new_name)) }
                      .map { |c| c.update(File.join(output_dir, c.new_name)) }

    puts '== NEW FILE NAMES ============= VERIFY THIS'
    # TODO pretty-print this in two aligned columns
    puts all_changes
    puts

    output_dir_contents = all_changes.map { |c| File.basename(c.new_name) }

    puts '== OUTPUT DIR CONTENTS ======== VERIFY THIS'
    puts(output_dir_contents.length ? output_dir_contents : 'empty')
    puts

    collision_output_files = output_dir_contents - output_dir_contents.uniq

    puts('== OUTPUT FILE COLLISIONS ===== ' + (collision_output_files.length ? 'GOOD! NO COLLISIONS' : 'BAD!'))
    puts(collision_output_files.length ? collision_output_files : 'none')
    puts

    # TODO if the flag is set, actually perform this operation
  end
end

Main.run