mdSlide
===

![mdSlide](screenshot.png)

Presentation writer with markdown (Powered by Electron)

## Usage

### Install and execute

[Please download latest archives from release page.](https://github.com/yhatt/mdslide/releases) You can put unpacked files to your any folder.

- **Windows**: Unzip `*.*.*-mdslide-win32-[arch].zip` and run `mdslide.exe`
- **Mac OS X**: (Currently setting build system)
- **Linux**: Unpack `*.*.*-mdslide-linux-[arch].tar.gz` and run `mdslide`

## Develop

### Getting started

```
npm install
```

And run below gulp task:

```
gulp run
```

(or `gulp.bat run` on Windows)

#### Run Electron directly

Run `electron.bat` or `./node_modules/.bin/electron.cmd .` from console for executing mdSlide on Windows.

On Mac or Linux, run `./node_modules/.bin/electron .` from console. When direnv has installed, you can execute with `electron .` (If direnv blocked, please run `direnv allow`).

### Create release build

```
gulp release
```

Please set application version in `package.json`.

#### Notice

*Currently not supported building for Darwin.*
