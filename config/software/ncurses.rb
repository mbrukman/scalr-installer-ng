#
# Copyright 2012-2014 Chef Software, Inc.
# Copyright 2015 Scalr, Inc.
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

name 'ncurses'
default_version '5.9'

source url: "http://ftp.gnu.org/gnu/ncurses/ncurses-#{version}.tar.gz",
       md5: '8cb9c412e5f2d96bc6f459aa8c6282a1'

relative_path "ncurses-#{version}"

########################################################################
#
# wide-character support:
# Ruby 1.9 optimistically builds against libncursesw for UTF-8
# support. In order to prevent Ruby from linking against a
# package-installed version of ncursesw, we build wide-character
# support into ncurses with the "--enable-widec" configure parameter.
# To support other applications and libraries that still try to link
# against libncurses, we also have to create non-wide libraries.
#
# The methods below are adapted from:
# http://www.linuxfromscratch.org/lfs/view/development/chapter06/ncurses.html
#
########################################################################

build do
  env = with_standard_compiler_flags(with_embedded_path)

  # build wide-character libraries
  cmd = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    '--with-shared',
    '--with-termlib',
    '--without-debug',
    '--without-normal', # AIX doesn't like building static libs
    '--enable-overwrite',
    '--enable-widec',
    '--without-cxx-binding',
  ]

  command cmd.join(" "), env: env
  make "-j #{workers}", env: env
  make "-j #{workers} install", env: env

  # Build non-wide-character libraries
  make 'distclean', env: env

  cmd = [
    './configure',
    "--prefix=#{install_dir}/embedded",
    '--with-shared',
    '--with-termlib',
    '--without-debug',
    '--without-normal',
    '--enable-overwrite',
    '--without-cxx-binding',
  ]

  command cmd.join(" "), env: env
  make "-j #{workers}", env: env

  # Installing the non-wide libraries will also install the non-wide
  # binaries, which doesn't happen to be a problem since we don't
  # utilize the ncurses binaries in private-chef (or oss chef)
  make "-j #{workers} install", env: env
end