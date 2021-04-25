# frozen_string_literal: true

name 'prometheus-platform'
maintainer 'Chef Platform'
maintainer_email(
  'incoming+chef-platform/prometheus-platform@incoming.gitlab.com'
)
license 'Apache-2.0'
description 'Cookbook used to install and configure prometheus'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url 'https://gitlab.com/chef-platform/prometheus-platform'
issues_url 'https://gitlab.com/chef-platform/prometheus-platform/issues'
version '2.2.0'

chef_version '>= 12.14'

depends 'cluster-search'
depends 'ark'

supports 'centos', '>= 7.1'
