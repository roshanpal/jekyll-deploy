#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'

Dir.chdir('jekyll')

def system_or_fail(*cmd)
  exit $CHILD_STATUS unless system(*cmd)
end

system_or_fail('bundle', 'config', 'set', 'path', 'vendor/gems')
system_or_fail('bundle', 'config', 'set', 'deployment', 'true')
system_or_fail('bundle', 'install', '--jobs=4', '--retry=3')

if ENV['INPUT_BUILD-ONLY'] == "true"
  system_or_fail('bundle', 'exec', 'jekyll', 'build', '--future', '--verbose', '--trace')
  exit
else
  system_or_fail('bundle', 'exec', 'jekyll', 'build', '--verbose', '--trace')
end

Dir.chdir('./../')
#Dir.chdir('_site')
Dir.mkdir('deploy')
FileUtils.copy_entry('./jekyll/_site', 'deploy/blog')

File.open('.nojekyll', 'w') { |f| f.puts 'Skip Jekyll' }

Dir.chdir('./deploy')
system_or_fail('git', 'init', '.')
FileUtils.cp('../.git/config', '.git/config')
FileUtils.remove_dir('../.git')
system_or_fail('pwd')
system_or_fail('cp', '-r', '../assets', '.')
system_or_fail('cp', '../favicon.ico', '.')
system_or_fail('cp', '../index.html', '.')
system_or_fail('cp', '../CNAME', '.')
#FileUtils.copy_entry('../*', '.')
system_or_fail('git', 'config', 'user.name', ENV['GITHUB_ACTOR'])
system_or_fail('git', 'config', 'user.email', "#{ENV['GITHUB_ACTOR']}@users.noreply.github.com")
system_or_fail('git', 'fetch', '--no-tags', '--no-recurse-submodules', '--depth=1', 'origin', '+gh-pages:refs/remotes/origin/gh-pages')
system_or_fail('git', 'reset', '--soft', 'origin/gh-pages')
system_or_fail('git', 'add', '-A', '.')
system_or_fail('git', 'commit', '-m', 'Update github pages')
system_or_fail('git', 'push', 'origin', 'HEAD:gh-pages')

puts "triggering a github pages deploy"

require 'net/http'
result = Net::HTTP.post(
  URI("https://api.github.com/repos/#{ENV['GITHUB_REPOSITORY']}/pages/builds"),
  "",
  "Content-Type" => "application/json",
  "Authorization" => "token #{ENV['GH_PAGES_TOKEN']}",
)

puts result.body
