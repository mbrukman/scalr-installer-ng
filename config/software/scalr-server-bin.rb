#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
# Copyright:: Copyright (c) 2015 Scalr, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# __INSTALLER_REVISION__ # Used to bust the cache when a new revision is used (Omnibus caches based on file contents).

name 'scalr-server-bin'

source :path => File.expand_path('files/scalr-server-bin', Omnibus::Config.project_root)

build do
  command "rsync -a ./ #{install_dir}/bin"
end