mdSlide
===

![mdSlide](screenshot.png)

Presentation writer with markdown (Powered by Electron)

## Usage

### Install

[Please download latest archives from release page.](https://github.com/yhatt/mdslide/releases)

##### Windows

Unzip `*.*.*-mdSlide-win32-[arch].zip` and run `mdSlide.exe`.

##### Mac OS X

Mount `*.*.*-mdSlide-darwin-x64.dmg`, D&D `mdSlide` to `Applications` and run it from Applications folder / Launchpad.

##### Linux

Unpack `*.*.*-mdSlide-linux-[arch].tar.gz` and run `mdSlide`.

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

### Create release build

```
gulp release
```

Set application version in `package.json`.

#### Windows

If you want to build for Windows in other platforms, please install [Wine](https://www.winehq.org/) to change Electron's resources.

#### OSX

To build for Darwin is only supported in OSX. Please install [gulp-appdmg](https://github.com/Aluxian/gulp-appdmg) to create archive (`.dmg`) for Darwin release.

```
npm install gulp-appdmg
```

*Notice: **Don't add to development dependency of `package.json`.** The release task would fail in other platforms.*
