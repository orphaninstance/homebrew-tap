#!/usr/bin/env ruby
# .github/scripts/bump_casks.rb
require 'json'
require 'open3'

# Configuration
TAP = "orphaninstance/homebrew-tap"

def run_command(cmd)
  stdout, stderr, status = Open3.capture3(cmd)
  unless status.success?
    warn "Error executing: #{cmd}"
    warn stderr
    return nil
  end
  stdout
end

def calculate_sha256(url)
  puts "Calculating SHA for #{url}..."
  res = run_command("curl -sL \"#{url}\" | shasum -a 256")
  return nil unless res
  res.split.first
end

def bump_cask(cask_name, new_version)
  puts "Bumping #{cask_name} to #{new_version}..."
  file_path = "Casks/#{cask_name}.rb"
  return false unless File.exist?(file_path)

  content = File.read(file_path)

  url_match = content.match(/url\s+"([^"]+)"/)
  return false unless url_match
  url_template = url_match[1]

  arch_keys = content.scan(/([a-z0-9_]+)_linux:\s+"[a-f0-9]{64}"/).flatten
  if arch_keys.empty?
    sha_match = content.match(/sha256\s+([a-z0-9_]+):\s+"/)
    arch_keys << sha_match[1] if sha_match
  end

  if arch_keys.empty?
    warn "Could not determine architectures for #{cask_name} from SHA keys."
    return false
  end

  updated_content = content.gsub(/version\s+".*"/, "version \"#{new_version}\"")

  arch_keys.each do |key|
    url_arch = key.sub("_linux", "")
    final_url = url_template
                .gsub("#{version}", new_version)
                .gsub("#{arch}", url_arch)

    sha = calculate_sha256(final_url)
    if sha.nil?
      warn "Failed to calculate SHA for #{key} at #{final_url}"
      return false
    end

    updated_content.gsub!(/#{key}:\s+"[a-f0-9]{64}"/, "#{key}: \"#{sha}\"")
  end

  File.write(file_path, updated_content)
  true
end

# Main execution
puts "Scanning for Casks in the local repository..."

cask_files = Dir.glob("Casks/*.rb")
if cask_files.empty?
  warn "Error: No casks found in Casks/ directory."
  exit 1
end

cask_names = cask_files.map { |f| File.basename(f, ".rb") }
puts "Checking updates for: #{cask_names.join(', ')}"

livecheck_output = run_command("brew livecheck --json #{cask_names.join(' ')}")
if livecheck_output.nil?
  warn "Error: brew livecheck failed to execute."
  exit 1
end

begin
  data = JSON.parse(livecheck_output)
rescue JSON::ParserError => e
  warn "Error parsing livecheck JSON: #{e.message}"
  exit 1
end

error_occurred = false
updated_count = 0

data.each do |item|
  name = item["cask"]

  if item.dig("version", "outdated")
    latest = item.dig("version", "latest")
    puts "Found outdated cask: #{name} (Latest: #{latest})"
    if bump_cask(name, latest)
      updated_count += 1
    else
      warn "Failed to bump #{name}"
      error_occurred = true
    end
  else
    puts "#{name} is up to date."
  end
end

if error_occurred
  exit 1 # Real failure occurred during bumping
else
  puts "Successfully processed updates. Casks updated: #{updated_count}"
  exit 0 # Job completed successfully, regardless of whether changes were made
end
