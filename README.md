
# 💫 The iOS 9+ share extension for [Shaarli](https://github.com/shaarli/Shaarli#readme). Once ShaarliOS, now #Shaarli💫

Share links with ease from every iOS app.

![Icon](shaarli-petal.svg)
[![App Store Badge](appstore/Download_on_the_App_Store_Badge_US-UK_135x40.svg)](https://itunes.apple.com/us/app/ShaarliOS/id1027441388?mt=8)

Please [rate the App ⭐️](https://apps.apple.com/us/app/shaarlios/id1027441388?mt=8&action=write-review) – whether you like it or not. Each rating is valuable.

## Support

If you encounter a bug, please
[file an issue 🐞](https://github.com/mro/ShaarliOS/issues/new?&body=Thank%20you%20for%20the%20report,%20please%20add%0a%0a-%20screenshot%20showing%20the%20bug,%0a-%20App%20version,%0a-%20Shaarli%20server%20version.)
or
[send me an email 📧](mailto:shaarlios-bug@mro.name?subject=[ShaarliOS]%20Bugreport&body=Thank%20you%20for%20the%20report,%20please%20add%0a%0a-%20screenshot%20showing%20the%20bug,%0a-%20App%20version,%0a-%20Shaarli%20server%20version.).

## Screenshots

![iPhone 4: Note](appstore/screenshots/en-US/1_iphone35_note.png#x200)
![iPhone 4: Share Settings](appstore/screenshots/en-US/2_iphone35_share_sheet.png#x200)
![iPhone 4: Share](appstore/screenshots/en-US/3_iphone35_share.png#x200)
![iPhad 2: Note](appstore/screenshots/en-US/1_ipad_note.png#x200)

## Compatibility

> !! future verions (1.5+) shall use an API, see https://mro.name/ShaarliO/api

All
[proper Shaarli versions](https://travis-ci.org/mro/Shaarli-API-test), both
[community fork](https://github.com/shaarli/Shaarli/releases) and
[vanilla](https://github.com/sebsauvage/Shaarli/releases), on more than
[all current PHP versions](http://php.net/supported-versions.php), all
[themes and templates](https://github.com/shaarli/shaarli-themes).

If your version is missing or you found a Shaarli that doesn't work, please file an
issue.

## License

- `shaarli-*.svg` by [idleman](http://blog.idleman.fr/), [zlib/libpng OSI licence](http://www.opensource.org/licenses/zlib-license.php),
- `*/*.svg */*.png` by [idleman](http://blog.idleman.fr/) and [mro](http://mro.name/~me), [zlib/libpng OSI licence](http://www.opensource.org/licenses/zlib-license.php),
- `*/ShaarliOS/3rd/KeychainPasswordItem.swift` by [Apple Inc.](https://apple.com), all rights reserved,
- `appstore/Download_on_the_App_Store_Badge_US-UK_135x40.svg` by [Apple Inc.](http://apple.com), all rights reserved,
- *all others* by [mro](http://mro.name/~me), [GPL v3](http://www.gnu.org/licenses/gpl-3.0.html)

## Credits

except the material used and listed above, I'm happy to thank

- [community Shaarli](https://github.com/shaarli/Shaarli) by [the github shaarli contributors](https://github.com/shaarli/Shaarli/graphs/contributors),
- [vanilla Shaarli](http://sebsauvage.net/wiki/doku.php?id=php:shaarli) by [sebsauvage](http://sebsauvage.net/),
- [Dimitri van Heesch's doxygen](http://www.stack.nl/~dimitri/doxygen/),
- [Ben Gardner's uncrustify](http://uncrustify.sourceforge.net/),
- all the [contributors to git](https://github.com/git/git/graphs/contributors),
- [Rowan James' GitX fork](http://rowanj.github.io/gitx/),
- [Inkscape communiy](https://inkscape.org/en/community/),
- [stackoverflow](http://stackoverflow.com/),
- [Apple Inc.](http://apple.com/).

## Privacy

When getting the App from the App Store, the terms and conditions of Apple apply https://www.apple.com/de/legal/privacy/

When posting, the terms of your own server (the one you post to) also apply.

The App itself collects no data.

## Design Goals

| Quality         | very good | good | normal | irrelevant |
|-----------------|:---------:|:----:|:------:|:----------:|
| Functionality   |           |      |    ×   |            |
| Reliability     |           |  ×   |        |            |
| Usability       |     ×     |      |        |            |
| Efficiency      |           |      |    ×   |            |
| Changeability   |           |  ×   |        |            |
| Portability     |           |      |        |      ×     |
