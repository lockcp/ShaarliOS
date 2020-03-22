
# 💫 The iOS 9+ share extension for [Shaarli](https://github.com/shaarli/Shaarli#readme). Once ShaarliOS, now #Shaarli💫

Share links with ease from every iOS app.

![Icon](shaarli-petal.svg)
[![App Store Badge](appstore/Download_on_the_App_Store_Badge_US-UK_135x40.svg)](https://itunes.apple.com/jp/app/ShaarliOS/id1027441388?mt=8)
[![Build Status](https://travis-ci.org/mro/ShaarliOS.svg?branch=master)](https://travis-ci.org/mro/ShaarliOS)

## Screenshots

![iPhone 4: Note](appstore/screenshots/en-US/1_iphone35_note.png#x200)
![iPhone 4: Share Settings](appstore/screenshots/en-US/2_iphone35_share_sheet.png#x200)
![iPhone 4: Share](appstore/screenshots/en-US/3_iphone35_share.png#x200)
![iPhad 2: Note](appstore/screenshots/en-US/1_ipad_note.png#x200)

## Compatibility

> !! future verions (1.3+) shall use an API, see https://mro.name/ShaarliO/api

All
[proper Shaarli versions](https://travis-ci.org/mro/Shaarli-API-test), both
[community fork](https://github.com/shaarli/Shaarli/releases) and
[vanilla](https://github.com/sebsauvage/Shaarli/releases), on more than
[all current PHP versions](http://php.net/supported-versions.php), all
[themes and templates](https://github.com/shaarli/shaarli-themes).

If your version is missing or you found a Shaarli that doesn't work,
[drop me a line](https://code.mro.name/mro/ShaarliOS/issues).

## Bug Reports

If you encounter a bug, I'd be grateful if you 
[open an issue here](https://github.com/mro/ShaarliOS/issues/new?title=Bug&body=Thank%20you%20very%20much%20for%20your%20bug%20report.%20I%20am%20very%20sorry%20for%20the%20inconvenience.%0D%0A%0D%0ATo%20be%20able%20to%20quickly%20hunt%20down%20and%20eliminate%20the%20bug,%20please%20include%20some%20additional%20information:%0D%0A%0D%0A-%20can%20you%20attach%20a%20screenshot%20of%20the%20bug%20and%20the%20last%20visible%20screen%20prior%20the%20bug%20(will%20be%20treated%20confidential)?%0D%0A-%20what%20is%20the%20Shaarli%20version%20you%20use%20(preferably%20the%20download%20URL%20you%20got%20it%20from)?%0D%0A-%20which%20template%20are%20you%20using%20(if%20other%20than%20the%20default,%20also%20preferably%20the%20download%20URL)?%0D%0A-%20are%20you%20using%20https,%20if%20so:%20who%20issued%20your%20certificate?%0D%0A-%20can%20you%20attach%20device%20logs%20or%20crash%20reports?%0D%0A%0D%0AThank%20you%20very%20much,%0D%0A%20%20%20%20Marcus%20Rohrmoser)
or — if not a github user —
[let me know via email](mailto:shaarlios@mro.name?subject=[ShaarliOS]%20Bugreport&body=Thank%20you%20very%20much%20for%20your%20bug%20report.%20I%20am%20very%20sorry%20for%20the%20inconvenience.%0D%0A%0D%0ATo%20be%20able%20to%20quickly%20hunt%20down%20and%20eliminate%20the%20bug,%20please%20include%20some%20additional%20information:%0D%0A%0D%0A-%20can%20you%20attach%20a%20screenshot%20of%20the%20bug%20and%20the%20last%20visible%20screen%20prior%20the%20bug%20(will%20be%20treated%20confidential)?%0D%0A-%20what%20is%20the%20Shaarli%20version%20you%20use%20(preferably%20the%20download%20URL%20you%20got%20it%20from)?%0D%0A-%20which%20template%20are%20you%20using%20(if%20other%20than%20the%20default,%20also%20preferably%20the%20download%20URL)?%0D%0A-%20are%20you%20using%20https,%20if%20so:%20who%20issued%20your%20certificate?%0D%0A-%20can%20you%20attach%20device%20logs%20or%20crash%20reports?%0D%0A%0D%0AThank%20you%20very%20much,%0D%0A%20%20%20%20Marcus%20Rohrmoser).

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

The terms of the server you post to also apply.

Other than that there's no data collection.

## Design Goals

| Quality         | very good | good | normal | irrelevant |
|-----------------|:---------:|:----:|:------:|:----------:|
| Functionality   |           |  ×   |        |            |
| Reliability     |           |      |    ×   |            |
| Usability       |     ×     |      |        |            |
| Efficiency      |           |      |    ×   |            |
| Changeability   |           |  ×   |        |            |
| Portability     |           |      |        |      ×     |
