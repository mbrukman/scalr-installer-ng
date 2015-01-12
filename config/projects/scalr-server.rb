# Note that changing this file invalidates the entire build.
name 'scalr-server'
maintainer 'Thomas Orozco <thomas@scalr.com>'
homepage 'https://www.scalr.com'

install_dir "#{default_root}/#{name}"

build_version Omnibus::BuildVersion.semver
build_iteration 1

override 'scalr-app', version: 'cee9a5dfc950daa018c685968a1b88bbb4dfb772'  # 5.1

# Creates required build directories
dependency 'local-preparation'

# Software we need to run
dependency 'mysql'
dependency 'rrdtool'
dependency 'cronie'

# Actual Scalr software
dependency 'scalr-app'

# App management
dependency 'chef-gem' # for embedded chef-solo
dependency 'scalr-server-cookbooks'   # Cookbooks to configure Scalr
dependency 'scalr-server-ctl'         # CLI to run chef-solo and actions (scalr-server-ctl)

# Version manifest file
dependency 'version-manifest'

exclude '**/.git'
exclude '**/bundler/git'
