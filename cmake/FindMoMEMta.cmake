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

find_path(
    MOMEMTA_INCLUDE_DIR 
    NAMES momemta/MoMEMta.h
    DOC "MoMEMta include dir"
)

find_library(
    MOMEMTA_LIBRARY
    NAMES libmomemta.so
    DOC "MoMEMta shared library"
)

set(MOMEMTA_INCLUDE_DIRS ${MOMEMTA_INCLUDE_DIR})
set(MOMEMTA_LIBRARIES ${MOMEMTA_LIBRARY})

# Handle the REQUIRED or QUIET flags when calling find_package(),
# and set the MoMEMta_FOUND variable
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(MoMEMta DEFAULT_MSG
        MOMEMTA_INCLUDE_DIR MOMEMTA_LIBRARY)
