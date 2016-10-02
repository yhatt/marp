---
category: top
---

<div class="col-xs-12" markdown="1">

# Directives

Marp's Markdown has extended directives to affect slides. Insert HTML comment as `<!-- {directive_name}: {value} -->`

</div>
<div class="col-xs-12 col-sm-6" markdown="1">

## Pagination

You want pagination? Insert `<!-- page_number: true -->` at the top.

If you want to exclude the first page number, move the directive to after the first ruler.

```markdown
# First page

The page number `1` is not shown.

---
<!-- page_number: true -->

# Second page

The page number `2` is shown!
```

</div>
<div class="col-xs-12 col-sm-6" markdown="1">

## Resize slide

You can resize slides with the Global Directive `$size`.
Insert `<!-- $size: 16:9 -->` if you want to display slides on 16:9 screen. That’s all!

```html
<!-- $size: 16:9 -->
```

`$size` directive supports `4:3`, `16:9`, `A0`-`A8`, `B0`-`B8` and the `-portrait` suffix.

Marp also supports `$width` and `$height` directives to set a custom size.

</div>
<div class="col-xs-12" markdown="1">

---

You want an example? Have a look at [example.md](https://raw.githubusercontent.com/yhatt/marp/master/example.md){:target="_blank"}.

</div>