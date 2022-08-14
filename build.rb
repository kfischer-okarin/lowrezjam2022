#!/usr/bin/env ruby

require 'fileutils'
require 'pathname'

require 'rubygems'
require 'bundler/setup'
require 'zip'

GAME_FOLDER_NAME = 'game'

def main
  build_game
  remove_build_directories
end

def build_game
  build_with_smaug
  ZipCreator.new.create_zips
end

def build_with_smaug
  system "smaug build -p #{GAME_FOLDER_NAME}"
end

# Create release zip files
class ZipCreator
  def initialize
    metadata = read_metadata
    @version = metadata[:version]
    @gameid = metadata[:gameid]
  end

  def create_zips
    reset_output_directory
    create_windows_zip
    create_macos_zip
    create_linux_zip
    move_html5_zip
  end

  private

  def read_metadata
    metadata = File.readlines(Pathname(GAME_FOLDER_NAME) / 'metadata' / 'game_metadata.txt', chomp: true)
    version_line = metadata.find { |line| line.include? 'version' }
    gameid_line = metadata.find { |line| line.include? 'gameid' }

    {
      gameid: gameid_line.split('=')[1],
      version: version_line.split('=')[1]
    }
  end

  def reset_output_directory
    FileUtils.rm_rf 'dist'
    FileUtils.mkdir_p 'dist'
  end

  def create_windows_zip
    zip_file = Pathname("dist/#{@gameid}-windows-v#{@version}.zip")
    Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
      zipfile.add("#{@gameid}.exe", built_file("#{@gameid}-windows-amd64.exe"))
    end
  end

  def create_macos_zip
    FileUtils.mv(built_file("#{@gameid}-macos.zip"), "dist/#{@gameid}-macos-v#{@version}.zip")
  end

  def create_linux_zip
    zip_file = Pathname("dist/#{@gameid}-linux-v#{@version}.zip")
    Zip::File.open(zip_file, Zip::File::CREATE) do |zipfile|
      zipfile.add("#{@gameid}.bin", built_file("#{@gameid}-linux-amd64.bin"))
    end
  end

  def move_html5_zip
    FileUtils.mv(built_file("#{@gameid}-html5.zip"), "dist/#{@gameid}-html5.zip")
  end
end

def remove_build_directories
  FileUtils.rm_rf Pathname(GAME_FOLDER_NAME) / 'builds'
  FileUtils.rm_rf 'tmp/demo'
end

def built_file(filename)
  Pathname(GAME_FOLDER_NAME) / 'builds' / filename
end

main if $PROGRAM_NAME == __FILE__
