mdSlide
===

**Markdown slide writer, powered by [Electron](http://electron.atom.io/).**

![mdSlide](screenshot.png)

## Usage

### Install

:arrow_forward: **[Download latest archives from release page.](https://github.com/yhatt/mdslide/releases)**

- **Windows**: Unzip `*.*.*-mdSlide-win32-[arch].zip` and run `mdSlide.exe`.
- **Mac OS X**: Mount `*.*.*-mdSlide-darwin-x64.dmg`, D&D `mdSlide` to `Applications` and run it from Applications folder / Launchpad.
- **Linux**: Unpack `*.*.*-mdSlide-linux-[arch].tar.gz` and run `mdSlide`.

### How to write slides?

Split slides by horizontal ruler `---`. It's very simple. Please refer to [example.md](https://raw.githubusercontent.com/yhatt/mdslide/master/example.md).

```md
# Slide 1

foobar

---

# Slide 2

foobar
```

## For developers

### Getting started

```
npm install
```

And run below gulp task to execute:

```
gulp run
```

### Create release builds

```
gulp release
```

Please set application version in `package.json`.

#### OS specific

##### Windows

If you want to build for Windows in other platforms, please install [Wine](https://www.winehq.org/) to rewrite Electron's resources.

##### OSX

To build for Darwin is only supported in OSX. Please install [gulp-appdmg](https://github.com/Aluxian/gulp-appdmg) to create archive (`.dmg`) for Darwin release.

```
npm install gulp-appdmg
```

*Notice:* **Don't add it to development dependency of `package.json`.** The release task would fail in other platforms.

## Licenses

Copyright &copy; 2016 [Yuki Hattori](https://github.com/yhatt).
This software released under the [MIT License](https://opensource.org/licenses/mit-license.php).
