Marp
===

# ![](images/marp.png)

##### Markdown presentation writer, powered by [Electron](http://electron.atom.io/)

###### Created by Yuki Hattori ( [@yhatt](https://github.com/yhatt) )

---

# Features

- **Slides can write by Markdown.**
- Cross-platform. Supported Windows, Mac, and Linux
- Live Preview with 3 modes
- Slide themes (`default`, `gaia`)
- Supports emoji :heart:
- Export your slides to PDF

---

# How to write slides?

Split slides by horizontal ruler `---`. It's very simple.

```md
# Slide 1

foobar

---

# Slide 2

foobar
```

> *Notice: Ruler (`<hr>`) is not display in Marp.*

---

# Directives

Marp's Markdown has extended directives to affect slides.

Insert HTML comment as below:
```html
<!-- {directive_name}: {value} -->
```

```html
<!--
{first_directive_name}:  {value}
{second_directive_name}: {value}
...
-->
```

---

## Page Directive

The page directive would apply to **current page and later**.
You should insert it *to top* when apply to all slides.

### `page_number`

Set `true` to show page number on slides. *See lower right!*

```html
<!-- page_number: true -->
```

<!--
page_number: true

Example is here. Pagination starts from this page.
If you use multi-line comment, directives should write to each new lines.
-->

---

### `template`

Set to use template of theme.

The `template` directive just enables that using theme supports templates.

```html
<!--
$theme: gaia
template: invert
-->

Example: Set "invert" template of Gaia theme.
```

---

## Global Directive

### `$theme`

Change slide theme.

```
<!-- $theme: gaia -->
```


##### Suported themes (v0.0.8)

|Theme name|Value|Directive|
|:-:|:-:|:-|
|***Default***|default|`<!-- $theme: default -->`
|**Gaia**|gaia|`<!-- $theme: gaia -->`


---

### `$width` / `$height`

Change slide width and height.
You can use units: `px` (default), `cm`, `mm`, `in`, `pt`, and `pc`.

```html
<!-- $width: 12in -->
```

### `$size`

Change slide size by presets.
Presets: `4:3`, `16:9`, `A0`-`A8`, `B0`-`B8` and suffix of `-portrait`.

```html
<!-- $size: 16:9 -->
```

<!--
$size: a4

Example is here. Global Directive is enabled in anywhere.
It apply the latest value if you write multiple same Global Directives.
-->

---

#### Pro Tips

Page Directive can apply temporally to only current slide. Try to add `*` to top of Page Directive name!

```
<!-- *page_number: false -->
<!-- *template: invert -->
```

<!--
*page_number: false

Example is here.
Page number is not shown in current page, but it's shown on later pages.
-->

---

## Enjoy writing slides! :+1:

### https://github.com/yhatt/marp

Copyright &copy; 2016 [Yuki Hattori](https://github.com/yhatt)
This software released under the [MIT License](https://github.com/yhatt/marp/blob/master/LICENSE).
