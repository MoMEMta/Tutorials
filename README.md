# Tutorials
This repository contains a set of working standalone examples illustrating the use of MoMEMta.

## Requirements

- MoMEMta >= 0.1.0
- A C++-11 capable compiler

**Notes**:
- This is the development branch of the Tutorials, meaning that compatibility with the latest development version of MoMEMta is not guaranteed.
To ensure the Tutorials work properly, select a branch corresponding to your installed version of MoMEMta.
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
