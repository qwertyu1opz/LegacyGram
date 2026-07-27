#!/usr/bin/env ruby
# Rewrites imports that point at headers bundled inside this checkout to direct,
# relative imports. This avoids Xcode 4's unreliable header-map resolution.

require 'pathname'

root = Pathname.new(File.expand_path(ARGV[0] || Dir.pwd))
unless (root / 'Telegraph.xcodeproj').directory?
  abort "Run from the Twelvium_Public 2 directory."
end

roots = {
  'LegacyComponents' => root / 'submodules/LegacyComponents/LegacyComponents',
  'Photos' => root / 'submodules/LegacyComponents/Photos',
  'PhotosUI' => root / 'submodules/LegacyComponents/PhotosUI',
  'SafariServices' => root / 'submodules/LegacyComponents/SafariServices',
  'WatchConnectivity' => root / 'submodules/LegacyComponents/WatchConnectivity',
  'WebKit' => root / 'submodules/LegacyComponents/WebKit',
  'Pushkit' => root / 'submodules/LegacyComponents/Pushkit',
  'SSignalKit' => root / 'thirdparty/SSignalKit/SSignalKit',
  'MTProtoKit' => root / 'submodules/MtProtoKit/MTProtoKit',
  'MtProtoKit' => root / 'submodules/MtProtoKit'
}

patterns = %w[**/*.h **/*.m **/*.mm **/*.c **/*.cc **/*.cpp]
files = patterns.flat_map { |pattern| Dir.glob((root / pattern).to_s) }.uniq
changed_files = 0
changed_imports = 0

files.each do |file_name|
  file = Pathname.new(file_name)
  text = File.binread(file)
  next if text.include?("\x00")

  replacements = 0
  fixed = text.gsub(/#import\s+<([A-Za-z0-9_+.-]+)\/([^>]+)>/) do |match|
    module_name = Regexp.last_match(1)
    header_name = Regexp.last_match(2)
    base = roots[module_name]
    candidate = base && base / header_name
    unless candidate && candidate.file?
      match
    else
      relative = candidate.relative_path_from(file.dirname).to_s
      replacements += 1
      "#import \"#{relative}\""
    end
  end

  next if replacements.zero?
  File.binwrite(file, fixed)
  changed_files += 1
  changed_imports += replacements
end

puts "Rewrote #{changed_imports} bundled-header imports in #{changed_files} files."
