## Hanafuda

**Hanafuda** is a special-purpose compiler toolchain for *directly* patching
[DOL executable files](http://wiibrew.org/wiki/DOL) deployed on the Nintendo
GameCube and Wii, compiled with CodeWarrior.

The toolchain is built on top of the highly modular and general-purpose
[LLVM project](http://llvm.org). This includes use of a modified
[Clang C/C++ frontend](http://clang.llvm.org/) to convey
[inline patch directives](#defining-patches) from the source to a link-time patching
routine in a modified [LLD ELF Linker](http://lld.llvm.org/).

Game and SDK symbols discovered in a particular game need to be
assembled into a list file of the form:

```
0x80003130 start
0x80003140 __start
0x80003278 __init_registers
0x80003294 __init_data
0x80003354 __init_hardware
0x80003374 __flush_cache
0x800033A8 memset
0x800033D8 __fill_mem
0x80003490 memcpy
...
```

Game modders may distribute this list in a modding kit along with header files
redeclaring the classes, functions and variables.

### Changes From Vanilla LLVM

Hanafuda is essentially 99.9% LLVM + Clang + LLD. Specific changes include:

* **`#pragma patch_dol(<old-declarator>, <new-declarator>)`** AST and IR-metadata representations.
* **Forced LTO compilation** ensures IR-metadata is intact to linker.
* Support **Macintosh (Classic era) [C++ ABI symbol mangling](https://github.com/AxioDL/clang/blob/hanafuda/lib/AST/MacintoshMangle.cpp)**.
* Merge and update **[Tilka's paired-singles branch](https://github.com/Tilka/llvm-ppc750cl)**.
* Entirely custom **[Hanafuda LLD Driver](https://github.com/AxioDL/lld/blob/hanafuda/ELF/HanafudaDriver.cpp)**.
* **PPC-EABI target** with [small data section allocation](https://reviews.llvm.org/D26344).

### Installing From Packages

Hanafuda may be installed alongside an existing LLVM toolchain or on its own.
The package is uniquely identified with `AxioDL` as vendor and 
`ProgramFiles/llvm-hanafuda` or `opt/hanafuda` as install prefix.

#### Windows 7+

[llvm-hanafuda-4.0.0svn-win64.exe](https://github.com/AxioDL/hanafuda/releases/download/v4.0.0/llvm-hanafuda-4.0.0svn-win64.exe)

Windows 7 users may need the
[v14 Visual C++ runtime](https://www.microsoft.com/en-us/download/details.aspx?id=53840)
if not already installed.

#### macOS 10.9+

[llvm-hanafuda-4.0.0svn-Darwin.tar.xz](https://github.com/AxioDL/hanafuda/releases/download/v4.0.0/llvm-hanafuda-4.0.0svn-Darwin.tar.xz)

#### Arch Linux

[llvm-hanafuda-4.0-1-x86_64-archlinux.pkg.tar.xz](https://github.com/AxioDL/hanafuda/releases/download/v4.0.0/llvm-hanafuda-4.0-1-x86_64-archlinux.pkg.tar.xz)

```sh
sudo pacman -U llvm-hanafuda-4.0-1-x86_64-archlinux.pkg.tar.xz
```

### Building From Source

Hanafuda uses a CMake cache-based method for configuring the toolchain build.

An installation of `git`, `cmake` and `python` is required to build Hanafuda
(much like LLVM itself). [Ninja](https://ninja-build.org/) is the recommended
build system. **Be sure to have ~20GB of free disk space; especially when making
a debug build!!!**

The basic build + package process with Ninja works like so:

```sh
mkdir hanafuda
cd hanafuda
git clone https://github.com/AxioDL/llvm.git
cd llvm/tools
git clone https://github.com/AxioDL/clang.git
git clone https://github.com/AxioDL/lld.git
cd ../..
mkdir build
cd build
cmake -G Ninja -C ../llvm/tools/clang/cmake/caches/Hanafuda-stage2.cmake ../llvm
ninja
ninja package
```

The LLVM website has a [plethora of documentation](http://llvm.org/docs/CMake.html)
on fine-tuning the build for your host system.

### Using Hanafuda

`hanafuda` and `hanafuda++` work just like the `clang` and `clang++` drivers
(which work much like `gcc` and `g++`).

`--hanafuda-base-dol=` is a required argument that establishes the base patching
environment for hanafuda. It should ideally be an *unmodified* .dol ripped from
a game to be patched.

`--hanafuda-dol-symbol-list=` is how the list of original addresses and symbol names
gets paired with the .dol file.

Here's an example:

```sh
hanafuda++ -o patched_boot.dol --hanafuda-base-dol=RippedGame/boot.dol --hanafuda-dol-symbol-list=GamePatchingKit/GameSymbols.lst -I GamePatchingKit/include patch.cpp
```

### Defining Patches

With hanafuda, patches are defined from within the source itself using
`#pragma patch_dol(old_decl, new_decl)`. Any references to `old_decl` in the ripped
.dol are re-pointed to `new_decl`, which may be another original function or a newly
defined one in the patch sources.

Here's an example overriding the main() call of a game:

```cpp
extern "C" {

// Forward Declarations (may also be distributed in a header)
int main(int argc, char** argv);
void OSReport(const char*);

// New main() definition (must be uniquely named against original symbols)
int patched_main(int argc, char** argv) {
    int ret = main(argc, argv);
    OSReport("IM DYING\n");
    return ret;
}

// patch_dol() must be within extern "C" {} when patching C-linked symbols.
#pragma patch_dol(int main(int,char**), int patched_main(int,char**))

}
```

### Verbose Feedback

To see actions taken by the hanafuda linker, add `-Xlinker -verbose` to the
command-line.

Example output:

```
Patching 'IsUnderBetaMetroidAttack__7CPlayerCFR13CStateManager' to 'UpdateHealth__FP7CPlayerR13CStateManager'
Patched 0x80015370(0x000122D0) from 0x800129E4 to 0x805AF500 as R_PPC_REL24
Patched 0x80015268(0x000121C8) from 0x800129E4 to 0x805AF500 as R_PPC_REL24
Patched 0x80012F24(0x0000FE84) from 0x800129E4 to 0x805AF500 as R_PPC_REL24
Patched 0x80012AEC(0x0000FA4C) from 0x800129E4 to 0x805AF500 as R_PPC_REL24
```
