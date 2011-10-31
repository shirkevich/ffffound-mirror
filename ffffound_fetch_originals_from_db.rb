#!/usr/bin/env ruby
require 'rubygems'
require "bundler/setup"

require 'etc' 
require 'hpricot'
require 'json'
require 'open-uri'
require 'sqlite3'
require 'sequel'
require 'time'
require 'date'
require 'filemagic'

def fetch_orignals(db)
  db[:images].all.each do |image|
    download_file(image)
  end
end

def download_file(image)
  filename = image[:id]
  url = "http://" + image[:orig_img]

  full_file_path = "originals/#{filename}"
  fm = FileMagic.new(FileMagic::MAGIC_MIME)
  if Dir.glob("#{full_file_path}*").empty?
    begin
      out_file = open(full_file_path, 'wb')
      out_file.write(open(url).read)
      out_file.close
    rescue
      puts '! error with '+url
    end
    
    mime = fm.file(full_file_path).split(';')[0]
    ext = get_extension_from_mime(mime)
    if ext
      puts "Original file saved #{full_file_path}"
    else
      # get image from ffffound
      out_file = open(full_file_path, 'wb')
      out_file.write(open(image[:ffffound_img]).read)
      out_file.close
      mime = fm.file(full_file_path).split(';')[0]
      ext = get_extension_from_mime(mime)
      puts "File from ffffound saved #{full_file_path}"
    end
    
    if ext
      FileUtils.mv(full_file_path, "#{full_file_path}.#{ext}")
    else
      puts "Can't save file #{image[:id]}"
    end
  else
    puts "Image #{image[:id]} already processed"
  end
end

def get_extension_from_mime(mime)
  case mime
  when 'image/jpeg'
    'jpg'
  when 'image/gif'
    'gif'
  when 'image/png'
    'png'
  else
    nil
  end
end

# this needs work
user = ARGV[0] 
type = ARGV[1] || 'found'

if not user
  puts "A ffffound username must be supplied"
  exit
else
  if user == "--all"
     puts "Invoked for all posts"
     user = "all"
  end
  puts "Invoked for posts by #{user} of type #{type}"
end

FileUtils.mkdir "originals" rescue nil

path = 'db/ffffound-'+user+'.db' # ick
db = Sequel.sqlite(path)

fetch_orignals(db)
exit

# puts img.to_json 
# DONE puts img.to_database_table(s)
