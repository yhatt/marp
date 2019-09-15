<p align="center">
  <a href="https://marp.app/">
    <img alt="It's a time to migrate into Marp Next!" src="docs/ogp.png" height="240" />
  </a>
</p>

# It's a time to migrate into [Marp Next]!

**The publication of classic Marp app has ended.**

Marp desktop app, _a simple Markdown presentation writer_, already had stopped maintenance since 2017. Today [Marp team] is focusing into [Marp Next] project, the brand-new presentation ecosystem for the future.

_[See more details in our blog post.](https://marp.app/blog/the-story-of-marp-next)_

## Why?

We had kept publishing app for stuck users that are thinking Marp Next is too complex.

But recently, we received [a serious security report for outdated app](https://github.com/yhatt/marp/issues/276). **_By opening a malicious Markdown, an attacker can execute arbitrary code through remote._** We are responsible for saving users from malicious.

If you are currently using Marp app, **_please stop using as soon as possible_** and migrate into well-maintained Marp Next tools.

## [Marp Next] tools

[Marp Next] is not complex! Simply you can just use either one if you want to create slide deck.

### [Marp for VS Code]&nbsp;(Recommended)

**[Marp for VS Code]**, an extension for [Visual Studio Code], is the best alternative for desktop app users. There are key features inherited from the classic Marp app.

- Live preview
- Export to PDF, HTML, and PPTX (via [Marp CLI])
- Support built-in 3 themes and custom theme CSS

### [Marp CLI]

**[Marp CLI]** is simple but powerful CLI converter from Marp Markdown into PDF, HTML, PPTX, and images. You can use it if you don't want GUI editor.

I also have [an example repository](https://github.com/yhatt/marp-cli-example) to automate generating slide deck and serving through [Marp CLI] + [Netlify](https://www.netlify.com/) or [ZEIT Now](https://zeit.co/).

## Migrate Markdown

Marp Next is losing Markdown compatibility with classic app, but your slide would keep appearance as before just by some changes in most cases. Please see [our blog post](https://marp.app/blog/the-story-of-marp-next#migration-plan) for details.

## Thanks

Thanks for a lot of users / contributors of desktop app. Marp has changed my life as developer without doubt, and I've learned a lot from many feedbacks.

Now [Marp Next] project is evolving built on them. I hope you like it too.

---

_— Yuki Hattori ([@yhatt](https://github.com/yhatt))_

[marp next]: https://marp.app/
[marp team]: https://github.com/marp-team/
[marp for vs code]: https://marketplace.visualstudio.com/items?itemName=marp-team.marp-vscode
[marp cli]: https://github.com/marp-team/marp-cli
[visual studio code]: https://code.visualstudio.com
