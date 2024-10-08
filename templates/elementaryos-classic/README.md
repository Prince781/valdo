# ${PROJECT_NAME}

${PROJECT_SUMMARY}

## Building, Testing, and Installation

You'll need the following dependencies to build:
* libgtk-3-dev
* meson
* valac

Run `meson build` to configure the build environment and run `ninja` to build
```Bash
    meson build --prefix=/usr
    cd build
    ninja
```
To install, use `ninja install`, then execute with `com.${USERNAME}.${PROGRAM_NAME}`
```Bash
    sudo ninja install
    com.github.${USERNAME}.${PROGRAM_NAME}
```
