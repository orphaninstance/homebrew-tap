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

  # 1. Extract the URL template from the file
  url_match = content.match(/url\s+"([^"]+)"/)
  return false unless url_match
  url_template = url_match[1]

  # 2. Identify architectures based on existing sha256 keys
  arch_keys = content.scan(/([a-z0-9_]+)_linux:\s+"[a-f0-9]{64}"/).flatten
  if arch_keys.empty?
    sha_match = content.match(/sha256\s+([a-z0-9_]+):\s+"/)
    arch_keys << sha_match[1] if sha_match
  end

  if arch_keys.empty?
    warn "Could not determine architectures for #{cask_name} from SHA keys."
    return false
  end

  # 3. Update version and SHAs
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

# Find all .rb files in the Casks directory to get a list of names
cask_files = Dir.glob("Casks/*.rb")
if cask_files.empty?
  puts "No casks found in Casks/ directory."
  exit 1
end

cask_names = cask_files.map { |f| File.basename(f, ".rb") }
puts "Checking updates for: #{cask_names.join(', ')}"

# Run livecheck on the specific list of names found in the repo
livecheck_output = run_command("brew livecheck --json #{cask_names.join(' ')}")
exit 1 if livecheck_output.nil?

data = JSON.parse(livecheck_output)
updated_any = false

data.each do |item|
  name = item["name"]
  status = item["status"]
  latest = item["latest"]

  if status == "outdated"
    puts "Found outdated cask: #{name} (Latest: #{latest})"
    updated_any ||= bump_cask(name, latest)
  else
    puts "#{name} is up to date."
  end
end

if updated_any
  puts "BUMP_SUCCESSFUL=true"
  exit 0
else
  puts "No updates required."
  exit 1
end
