# Tutorials and examples for MoMEMta, the Modular Matrix Element Method implementation 
# 
# Copyright (C) 2016  Universite catholique de Louvain (UCL), Belgium
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

cmake_minimum_required(VERSION 2.8)
project(MoMEMta-Tutorials)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -Wall -pedantic -Wextra")

# Find dependencices

# CMake will automagically also link to MoMEMta's dependencies, ie LHAPDF and ROOT
find_package(MoMEMta CONFIG REQUIRED)

# But MoMEMta doesn't use TreePlayer: we have to add it ourselves
find_library(ROOT_TREEPLAYER_LIBRARY TreePlayer HINTS ${ROOT_LIBRARY_DIR} REQUIRED)

# Retrieve all the tutorials & examples
add_subdirectory(TTbar_FullyLeptonic)
add_subdirectory(WW_FullyLeptonic)

