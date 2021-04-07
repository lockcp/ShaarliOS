/*
 * https://developer.apple.com/library/archive/documentation/General/Conceptual/ExtensibilityPG/ExtensionScenarios.html#//apple_ref/doc/uid/TP40014214-CH21-SW12
 * https://github.com/wordpress-mobile/WordPress-iOS/blob/develop/WordPress/WordPressShareExtension/WordPressShare.js
 */
var Scraper = function() {};

Scraper.prototype = {
    run: function(arguments) {
        /*  https://codeberg.org/mro/ShaarliGo/src/branch/develop/tpl/tools.html */
        const url = document.location.href; // not convinced baseURI is a better choice
        /* scrape */
        /* precedence like comb.go#L54 */
        const tit = document.title
            ?? document.querySelector('meta[name=\'title\']')?.content
            ?? document.querySelector('meta[property=\'og:title\']')?.content
            ?? '';
        const tgs = document.querySelector('meta[name=\'keywords\']')?.content
            ?? document.querySelector('meta[name=\'news_keywords\']')?.content
            ?? '';
        const con = document.getSelection()?.toString()
            || document.querySelector('meta[name=\'description\']')?.content
            || '';
        const img = document.querySelector('meta[property=\'og:image\']')?.content
            ?? '';

        arguments.completionFunction({
            "url": url,
            "title": tit,
            "description": con,
            "keywords": tgs,
            "image": img,
        });
    }
};

var ExtensionPreprocessingJS = new Scraper;
