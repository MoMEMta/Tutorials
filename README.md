# Tutorials
This repository contains a set of working standalone examples illustrating the use of MoMEMta:
- `TTbar_FullyLeptonic`: compute weights under the hypothesis of top quark pair production with fully leptonic decay
- `WW_FullyLeptonic`: compute weights under the hypothesis of W boson pair production with fully leptonic decay
- `Paper_configs`: Lua configuration files for the different examples presented in the MoMEMta reference paper (only the configurations are provided, no fully working examples)

## Requirements

- MoMEMta v1.0.X
- A C++-11 capable compiler
- CMake (>= 3.4.0)

**Notes**:
- This branch of the Tutorials is only compatible with versions 1.0.X of MoMEMta
- MoMEMta needs to be installed on the system (locally or globally), cf. MoMEMta documentation

## Install

- Clone the repository or download and extract the archive.
- Execute the following in the `Tutorials` folder:
```
mkdir build
cd build
cmake ..
make -j 4
```

The following options are available when configuring the build (when running `cmake ..`):
- `-DCMAKE_PREFIX_PATH=(path)`: Path to the installation of MoMEMta. **Must be specified** if your version of MoMEMta is installed locally and not in your system directories. Caution: relative paths do not work.

## Run

You now have a set of executables located in sub-folders of the `build` directory. 
However, these cannot be executed yet: you need to build the matrix elements yourself,
just like when you export them using MoMEMta-MaGMEE and copy them to your project's directory.

For instance, to build the `TTbar_FullyLeptonic` example's matrix element, do:
```
cd ../TTbar_FullyLeptonic/MatrixElement/
mkdir build
cd build
cmake .. # If you had to specify the `CMAKE_PREFIX_PATH´ when building the tutorials, you'll have to do it here as well
make -j 4
```
This creates a shared library that can be loaded dynamically by MoMEMta. The example can now be executed:
```
cd ../../../build/
TTbar_FullyLeptonic/TTbar_FullyLeptonic.exe
```
