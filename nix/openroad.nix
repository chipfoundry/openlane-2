# Copyright 2023 Efabless Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
{
  lib,
  clangStdenv,
  fetchFromGitHub,
  openroad-abc,
  libsForQt5,
  opensta,
  boost183,
  eigen,
  cudd,
  ninja,
  tcl,
  python3,
  readline,
  tclreadline,
  spdlog-internal-fmt,
  libffi,
  llvmPackages,
  lemon-graph,
  or-tools,
  glpk,
  zlib,
  clp,
  cbc,
  re2,
  swig4,
  pkg-config,
  cmake,
  gnumake,
  flex,
  bison,
  clang-tools_14,
  buildEnv,
  makeBinaryWrapper,
  buildPythonEnvForInterpreter,
  rev ? "b061a21c943fadaca8f972a73f802eca15449935",
  sha256 ? "sha256-VRJEfCPml1nDZ4AINjKfyrxBKofMf9TjytPFfVIFRTY=",
}: let self = clangStdenv.mkDerivation (finalAttrs: {
    name = "openroad";
    inherit rev;

    src = fetchFromGitHub {
      owner = "The-OpenROAD-Project";
      repo = "OpenROAD";
      inherit rev;
      inherit sha256;
    };

    cmakeFlagsAll = [
      "-DTCL_LIBRARY=${tcl}/lib/libtcl${clangStdenv.hostPlatform.extensions.sharedLibrary}"
      "-DTCL_HEADER=${tcl}/include/tcl.h"
      "-DUSE_SYSTEM_BOOST:BOOL=ON"
      "-DENABLE_TESTS:BOOL=OFF"
    ];

    cmakeFlags =
      finalAttrs.cmakeFlagsAll
      ++ [
        "-DUSE_SYSTEM_ABC:BOOL=ON"
        "-DUSE_SYSTEM_OPENSTA:BOOL=ON"
        "-DOPENSTA_HOME=${opensta}"
        "-DCMAKE_CXX_FLAGS=-I${eigen}/include/eigen3"
        "-DABC_LIBRARY=${openroad-abc}/lib/libabc.a"
      ];

    preConfigure = ''
      sed -i "s/GITDIR-NOTFOUND/${rev}/" ./cmake/GetGitRevisionDescription.cmake
      patchShebangs ./etc/find_messages.py
      
      sed -i 's@# tclReadline@target_link_libraries(openroad readline)@' src/CMakeLists.txt
      sed -i 's@''${TCL_LIBRARY}@''${TCL_LIBRARY}\n${cudd}/lib/libcudd.a@' src/CMakeLists.txt
    '';

    buildInputs = [
      openroad-abc
      boost183
      eigen
      cudd
      tcl
      python3
      readline
      tclreadline
      spdlog-internal-fmt
      libffi
      libsForQt5.qtbase
      libsForQt5.qt5.qtcharts
      llvmPackages.openmp

      lemon-graph
      or-tools
      opensta
      glpk
      zlib
      clp
      cbc
      re2
    ];

    nativeBuildInputs = [
      swig4
      pkg-config
      cmake
      ninja
      gnumake
      flex
      bison
      libsForQt5.wrapQtAppsHook
      clang-tools_14
    ];

    shellHook = ''
      export DEVSHELL_CMAKE_FLAGS="${builtins.concatStringsSep " " finalAttrs.cmakeFlagsAll}"
    '';
    
    passthru = {
      inherit python3;
      withPythonPackages = buildPythonEnvForInterpreter {
        target = self;
        inherit lib;
        inherit buildEnv;
        inherit makeBinaryWrapper;
      };
    };

    meta = with lib; {
      description = "OpenROAD's unified application implementing an RTL-to-GDS flow";
      homepage = "https://theopenroadproject.org";
      # OpenROAD code is BSD-licensed, but OpenSTA is GPLv3 licensed,
      # so the combined work is GPLv3
      license = licenses.gpl3Plus;
      platforms = platforms.linux ++ platforms.darwin;
    };
  }); in self
