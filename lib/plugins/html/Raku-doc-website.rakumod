use v6.d;
use RakuDoc::Render;
use RakuDoc::PromiseStrings;
#| replaces HTML Bulma plugin
unit class Elucid8::Plugin::HTML::Raku-Doc-Website;
has %.config =
    :name-space<Raku-webs>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst, "https://https://bulma.io , MIT License">,
	:authors<finanalyst>,
	:css-link(['href="https://cdn.jsdelivr.net/npm/bulma@1.0.1/css/bulma.min.css"',1],),
	:js-link(['src="https://rawgit.com/farzher/fuzzysort/master/fuzzysort.js"',1],),
    :js([self.js-text,9],), # make sure its called last
    :scss([self.chyron-scss,1], [ self.toc-scss, 1], [ self.bulma-additions-scss, 1], [ self.raku-webs-scss, 1]),
    ui-tokens => %(
        :TOC<Table of Contents>,
        :NoTOC<No Table of contents for this page>,
        :ChangeTheme<Change Theme>,
        :Index<Index>,
        :NoIndex<No Index for this page>,
        :FileSource<Source file:>,
        :SourceModified<Source last modified:>,
        :Time( 'eval' ~ q|{ sprintf( "Rendered at %02d:%02d UTC on <br>%s", .hour, .minute, .yyyy-mm-dd) with now.DateTime }| ),
        :Intro<Introduction>,
        :IntroText<Getting started, Tutorials, Migration guides>,
        :Reference<Reference>,
        :ReferenceText<Fundamentals, General reference>,
        :Misc<Miscellaneous>,
        :MiscText<Programs, Experimental>,
        :Types<Types>,
        :TypesText<The core types (classes) available>,
        :Routines<Routines>,
        :RoutinesText<Searchable table of routines>,
        :RakuHome«Raku<sup>®</sup>»,
        :RakuHomeText<Home page for community>,
        :Chat<Chat>,
        :ChatText<IRC live chat>,
        :More<More>,
        :About<About>,
        :SiteReport<Report an issue with this site>,
        :DocReport<Report an issue with the documentation content>,
        :License<License>,
    )
;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-templates( $.templates, :source<Raku-doc-website plugin> );
    $rdp.add-data( %!config<name-space>, %!config );
}
#    { %tml<cancel-announcement-popup>.( {}, {} ) }
method templates {
    %(
        final => -> %prm, $tmpl {
            qq:to/PAGE/
            <!DOCTYPE html>
            <html { $tmpl<html-root> } >
                <head>
                <meta charset="UTF-8" />
                <meta name="viewport" content="width=device-width, initial-scale=1">
                { $tmpl<head-block> }
                { $tmpl<favicon> }
            </head>
            <body class="has-navbar-fixed-top">
                { $tmpl<top-of-page> }
                { $tmpl<main-content> }
                { $tmpl<footer> }
            </body>
            </html>
            PAGE
        },
        #| Required for index page
        Html => -> %prm, $ { %prm<raw> },
        #| head-block, what goes in the head tab
        head-block => -> %prm, $tmpl {
            my %g-data := $tmpl.globals.data;
            # handle css first
            qq:to/HEAD/
            <title>{$tmpl.globals.escape.(%prm<title>)}</title>
            { $tmpl<favicon> }
            {%g-data<css>:exists && %g-data<css>.elems ??
                [~] %g-data<css>.map({ '<style>' ~ $_ ~ "</style>\n" })
            !! ''
            }
            {%g-data<css-link>:exists && %g-data<css-link>.elems ??
                [~] %g-data<css-link>.map({ '<link rel="stylesheet" ' ~ $_ ~ "/>\n" })
            !! ''
            }
            {%g-data<js-link>:exists && %g-data<js-link>.elems ??
                [~] %g-data<js-link>.map({ '<script ' ~ $_ ~ "></script>\n" })
            !! ''
            }
            {%g-data<js>:exists && %g-data<js>.elems ??
                [~] %g-data<js>.map({ '<script>' ~ $_ ~ "</script>\n" })
            !! ''
            }
            HEAD
        },
        #| download the Camelia favicon
        favicon => -> %prm, $tmpl {
            q[<link rel="icon" href="https://irclogs.raku.org/favicon.ico">]
        },
        html-root => -> %prm, $tmpl {
           qq[lang="{%prm<source-data><language>}"
           class="theme-light"
           style="scroll-padding-top:var(--bulma-navbar-height)"]
        },
        #| the first section of body - site navigation, page navigation, search
        top-of-page => -> %prm, $tmpl {
            qq:to/NAV/
            <nav class="navbar is-fixed-top raku-webs" role="navigation" aria-label="main navigation">
                <div class="navbar-brand">
                { # remove TOC opener if direct-wrap exists and is true, or :!toc
                  (
                  (%prm<source-data><rakudoc-config><direct-wrap>:exists && %prm<source-data><rakudoc-config><direct-wrap>)
                   ||
                   (%prm<source-data><rakudoc-config><toc>:exists && %prm<source-data><rakudoc-config><toc>.not )
                   )
                   ??
                    ''
                    !! $tmpl<toc-opener>
                }
                 <figure class="navbar-item">
                    <a href="/{%prm<source-data><landing-page> ?? '' !! (%prm<source-data><language> ~ '/') }">
                        <img id="Camelia" class="is-rounded" src="https://avatars.githubusercontent.com/u/58170775">
                    </a>
                    <span class="navbar-tm-logo">tm</span>
                 </figure>
                 <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="navMenu">
                   <span aria-hidden="true"></span>
                   <span aria-hidden="true"></span>
                   <span aria-hidden="true"></span>
                   <span aria-hidden="true"></span>
                 </a>
                 </div>
                { $tmpl<site-navigation> }
            </nav>
            NAV
        },
        toc-opener => -> %prm, $ {
            q:to/TOC/
                <div class="navbar-start">
                    <label class="chyronToggle">
                      <input id="navbar-toc-toggle" type="checkbox" />
                      <span class="checkmark"> </span>
                    </label>
                </div>
            TOC
        },
        #| Side bar to hold ToC and Index
        #| The column itself is not visible for tablets+ and is there to move the main
        #| content when contents toggle is checked. Actual content
        #| is in a panel that floats on top of it
        sidebar => -> %prm, $tmpl {
            qq:to/BLOCK/;
                <div id="siteNavigation">
                    <!-- the following panel appears at the top of the page when form format is small -->
                    <nav class="panel is-hidden-tablet" id="mobile-nav">
                      <div class="panel-block">
                        <p class="control has-icons-left">
                          <input class="input" type="text" placeholder="Search" id="mobile-nav-search"/>
                          <span class="icon is-left">
                            <i class="fas fa-search" aria-hidden="true"></i>
                          </span>
                        </p>
                      </div>
                      <p class="panel-tabs">
                        <a id="mtoc-tab"><span class="Elucid8-ui" data-UIToken="TOC">TOC</span></a>
                        <a id="mindex-tab"><span class="Elucid8-ui" data-UIToken="Index">Index</span></a>
                      </p>
                        <aside id="mtoc-menu" class="panel-block">
                        { %prm<rendered-toc>
                            ?? %prm<rendered-toc>
                            !! '<p><span class="Elucid8-ui" data-UIToken="NoTOC">NoTOC</span></p>'
                        }
                        </aside>
                        <aside id="mindex-menu" class="panel-block is-hidden">
                        { %prm<rendered-index>
                            ?? %prm<rendered-index>
                            !! '<p><span class="Elucid8-ui" data-UIToken="NoIndex">NoIndex</span></p>'
                        }
                        </aside>
                    </nav>
                </div>
            </nav>
            BLOCK
        },
        #| Toc/Index floats below navbar except for mobile
        page-navigation => -> %prm, $tmpl {
           ( %prm<source-data><rakudoc-config><toc>:exists
            && %prm<source-data><rakudoc-config><toc>.not )
            ?? '' !!
            qq:to/SIDEBAR/;
            <nav class="raku-webs panel is-hidden-mobile" id="page-nav">
              <div class="panel-block">
                <p class="control has-icons-left">
                  <input class="input" type="text" id="page-nav-search"/>
                  <span class="icon is-left">
                    <i class="fas fa-search" aria-hidden="true"></i>
                  </span>
                </p>
              </div>
              <p class="panel-tabs">
                <a id="toc-tab"><span class="Elucid8-ui" data-UIToken="TOC">TOC</span></a>
                <a id="index-tab"><span class="Elucid8-ui" data-UIToken="Index">Index</span></a>
              </p>
                <aside id="toc-menu" class="panel-block">
                { %prm<rendered-toc>
                    ?? %prm<rendered-toc>
                    !! '<p><span class="Elucid8-ui" data-UIToken="NoTOC">NoTOC</span></p>'
                }
                </aside>
                <aside id="index-menu" class="panel-block is-hidden">
                { %prm<rendered-index>
                    ?? %prm<rendered-index>
                    !! '<p><span class="Elucid8-ui" data-UIToken="NoIndex">NoIndex</span></p>'
                }
                </aside>
            </nav>
            SIDEBAR
        },
        'site-navigation' => -> %prm, $tmpl {
            qq:to/BLOCK/
            <div id="navMenu" class="navbar-menu">
                <div class="navbar-start navbar-item is-hidden-touch"></div> <!-- empty item so remainder are centered -->
                <div class="navbar-start navbar-item is-hidden-desktop">{ $tmpl<head-search> }</div> <!-- move position of search with hamburger on -->
                <a class="navbar-item tooltip" href="/introduction">
                    <span class="Elucid8-ui" data-UIToken="Intro">Intro</span>
                    <span class="tooltiptext">
                    <span class="Elucid8-ui" data-UIToken="IntroText">IntroText</span>
                    </span>
                </a>
                <a class="navbar-item tooltip" href="/reference" >
					<span class="Elucid8-ui" data-UIToken="Reference">Reference</span>
					<span class="tooltiptext Elucid8-ui" data-UIToken="ReferenceText">ReferenceText</span>
                </a>
                <a class="navbar-item tooltip" href="/miscellaneous" >
					<span class="Elucid8-ui" data-UIToken="Misc">Miscellaneous</span>
					<span class="tooltiptext Elucid8-ui" data-UIToken="MiscText">MiscellaneousText</span>
                </a>
                <a class="navbar-item tooltip" href="https://raku.org" >
					<span class="Elucid8-ui" data-UIToken="RakuHome"></span>
					<span class="tooltiptext Elucid8-ui" data-UIToken="RakuHomeText">RakuHomeText</span>

                </a>
                <div class="navbar-item has-dropdown is-hoverable">
                    <a class="navbar-link">
                        <span class="Elucid8-ui" data-UIToken="More">More</span>
                    </a>
                    <div id="dropdown-container" class="navbar-dropdown is-rounded">
                        <div class="navbar-item">
                            <button id="changeTheme" class="button">
                                <span class="Elucid8-ui" data-UIToken="ChangeTheme">ChangeTheme</span>
                            </button>
                        </div>
                        <hr class="navbar-divider">
                        <a class="navbar-item" href="/about">
                            <span class="Elucid8-ui" data-UIToken="About">About</span>
                        </a>
                        <hr class="navbar-divider">
                        <a class="navbar-item tooltip" href="/types" >
                            <span class="Elucid8-ui" data-UIToken="Types">Types</span>
                            <span class="tooltiptext Elucid8-ui" data-UIToken="TypesText">TypesText</span>
                        </a>
                        <hr class="navbar-divider">
                        <a class="navbar-item tooltip" href="/routines" >
                            <span class="Elucid8-ui" data-UIToken="Routines">Routines</span>
                            <span class="tooltiptext Elucid8-ui" data-UIToken="RoutinesText">RoutinesText</span>
                        </a>
                        <hr class="navbar-divider">
                        <a class="navbar-item tooltip" href="https://kiwiirc.com/client/irc.libera.chat/#raku" >
                            <span class="Elucid8-ui" data-UIToken="Chat">Chat</span>
                            <span class="tooltiptext Elucid8-ui" data-UIToken="ChatText">ChatText</span>
                        </a>
                        <hr class="navbar-divider">
                        <a class="navbar-item has-text-red" href="https://github.com/raku/doc-website/issues">
                            <span class="Elucid8-ui" data-UIToken="SiteReport">SiteReport</span>
                        </a>
                        <hr class="navbar-divider">
                        <a class="navbar-item" href="https://github.com/raku/doc/issues">
                            <span class="Elucid8-ui" data-UIToken="DocReport">DocReport</span>
                        </a>
                    </div>
                </div>
                <div class="navbar-item has-dropdown is-hoverable" id="Elucid8_choice">
                    <a class="navbar-link"><span class="Elucid8-ui" data-UIToken="UI_Switch">UI_Switch</span></a>
                    { # this is provided by the UISwitcher plugin
                        $tmpl('ui-switch-contents', %(:classes<navbar-dropdown>))
                    }
                </div>
                <div class="navbar-end navbar-item is-hidden-touch"> <!-- move to top -->
                    { # provided by a search plugin
                        $tmpl<head-search>
                    }
                </div>
            <div id="modal-container"></div>
            BLOCK
        },
        # place-holders
        'head-search' => -> %, $ { 'No search function' },
        #| the main section of body
        main-content => -> %prm, $tmpl {
            if %prm<source-data><rakudoc-config><direct-wrap>:exists && %prm<source-data><rakudoc-config><direct-wrap>
            { # no extra styling if direct-wrap exists and is true
               %prm<body>
            }
            elsif ( %prm<source-data><rakudoc-config><toc>:exists && %prm<source-data><rakudoc-config><toc>.not )
            {
                qq:to/END/
                { $tmpl<page-navigation> }
                <div id="MainText" class="panel">
                    { $tmpl<title-section> }
                    <div class="content px-4">
                    { %prm<body> }
                    </div>
                    <div class="content px-4">
                    { %prm<footnotes>.Str }
                    </div>
                </div>
                END
            }
            else {
                qq:to/END/
                { $tmpl<page-navigation> }
                <div class="columns">
                    <div id="TOC" class="column is-one-quarter">
                        { $tmpl<sidebar> }
                    </div>
                    <div id="MainText" class="column">
                        { $tmpl<title-section> }
                        <div class="content px-4">
                        { %prm<body> }
                        </div>
                        <div class="content px-4">
                        { %prm<footnotes>.Str }
                        </div>
                    </div>
                </div>
                END
            }
        },
        #| title and subtitle
        title-section => -> %prm, $tmpl {
            my $rv = q:to/TOP/;
                <section class="section">
                  <div class="container">
                TOP
            if %prm<title-target>:exists and %prm<title-target> ne '' {
                $rv ~= qq[<div id="{
                    $tmpl.globals.escape.( %prm<title-target> )
                }"></div>]
            }
            $rv ~= '<h1 class="raku-webs title">' ~ %prm<title> ~ "</h1>\n\n" ~
            (%prm<subtitle> ?? ( '<p class="raku-webs subtitle">' ~ $tmpl.globals.escape.( %prm<subtitle> ) ~ "</p>\n" ) !! '') ~
            q:to/END/
                  </div>
                </section>
                END
        },
        #| special template to render the toc list
        toc => -> %prm, $tmpl {
            if %prm<toc-list>:exists && %prm<toc-list>.elems {
                PStr.new: qq[<div class="toc">] ~
                ([~] %prm<toc-list>) ~
                "</div>\n"
            }
            else {
                PStr.new: ''
            }
        },
        #| renders a single item in the index, but only if it has a non-heading ref
        index-item => -> %prm, $tmpl {
            my $n = %prm<level>;
            my @refs = %prm<refs>.grep(*.isa(Hash)).grep( *.<is-in-heading>.not ).map({
                    qq[<a class="raku-webs index-ref" href="#{ .<target> }">{ $tmpl.globals.escape.( .<place> ) }</a>]
                });
            if @refs.elems {
                PStr.new:
                    qq[<div class="raku-webs index-section" data-index-level="$n" style="--level:$n">\n] ~
                    '<span class="index-entry">' ~ %prm<entry> ~ '</span>' ~ ': ' ~
                    @refs.join(' ') ~
                    "\n</div>\n"
            }
            else { Nil }
        },
        #| special template to render the index data structure
        index => -> %prm, $tmpl {
            my @inds = %prm<index-list>.grep({ .isa(Str) || .isa(PStr) });
            if @inds.elems {
                PStr.new: '<div class="index">' ~ "\n" ~
                ([~] @inds ) ~
                "</div>\n"
            }
            else { '<span class="Elucid8-ui" data-UIToken="NoIndex">NoIndex</span>' }
        },
        #| the last section of body
        footer => -> %prm, $tmpl {
            qq:to/FOOTER/;
            <footer class="footer main-footer">
                <div class="container px-4">
                    <nav class="level">
                        <div class="level-item">
                            <span class="Elucid8-ui" data-UIToken="FileSource">Source</span><br><span class="footer-field">{%prm<source-data><name>}
                        </div>
                        <div class="level-item">
                            <span class="Elucid8-ui" data-UIToken="Time">Time</span>
                        </div>
                        <div class="level-item">
                            <span class="Elucid8-ui" data-UIToken="SourceModified">SourceModified</span><br>{(sprintf( " %02d:%02d UTC, %s", .hour, .minute, .yyyy-mm-dd) with %prm<source-data><modified>.DateTime)}
                        </div>
                        <div class="level-right">
                            <div class="level-item">
                              <a href="/license"><span class="Elucid8-ui" data-UIToken="License">License</span></a>
                            </div>
                        </div>
                    </nav>
                </div>
                { qq[<div class="section"><div class="container px-4 warnings">{%prm<warnings>}</div></div>] if %prm<warnings> }
            </footer>
            FOOTER
        },
        #| renders =head block
        head => -> %prm, $tmpl {
            my $del = %prm<delta> // '';
            my $h = 'h' ~ (%prm<level> // '1');
            my $classes = ( %prm<classes> // "heading raku-webs-$h" ) ~ ( 'delta' if $del ) ;
            my $caption = %prm<caption>.split(/ \< ~ \> <-[>]>+? /).join.trim;
            $caption = "%prm<numeration> $caption" if %prm<numeration>;
            my $targ := %prm<target>;
            my $esc-cap = $tmpl.globals.escape.( $caption );
            $esc-cap = '' if ($caption eq $targ or $esc-cap eq $targ);
            my $id-target = %prm<id>:exists && %prm<id>
                ?? qq[[\n<div class="id-target" id="{ $tmpl.globals.escape.(%prm<id>) }"></div>]]
                !! '';
            PStr.new:
                $id-target ~
                ( $esc-cap ?? qq[[\n<div class="id-target" id="$esc-cap"></div>]] !! '') ~
                qq[[<$h id="$targ" class="$classes {'delta' if $del}">]] ~
                ($del if $del) ~
                ($caption ?? (
                qq|<a href="#">| ~
                $caption ~
                qq|</a><a class="raku-webs-anchor" href="#{$esc-cap.so ?? $esc-cap !! $targ}">§\</a>| ~
                qq|</$h>\n|
                ) !! '')
        },
        table => -> %prm, $tmpl {
            %prm<classes> = 'table is-striped is-bordered' ~ (%prm<classes>:exists ?? ' ' ~ %prm<classes> !! '');
            $tmpl.prev(%prm)
        },
    )
}
method js-text {
    q:to/SCRIPT/;
    // RakuDoc-Website.js
    var change_theme = function (theme) {
        document.querySelector('html').className = '';
        document.querySelector('html').classList.add('theme-' + theme);
    };
    var persisted_theme = function () { return localStorage.getItem('theme') };
    var persist_theme = function (theme) { localStorage.setItem('theme', theme) };
    var persisted_tocState = function () { return localStorage.getItem('tocOpen') };
    var persist_tocState = function (tocState) { localStorage.setItem('tocOpen', tocState ) };
    var originalIndex;
    var originalTOC;
    var matchTocState = function ( state ) {
        if (document.getElementById("TOC") == null) { return };
        if ( state ) {
            document.getElementById("TOC").classList.remove('is-hidden');
            document.getElementById("page-nav").classList.remove('is-hidden');
            document.getElementById("mobile-nav").classList.remove('is-hidden');
            document.getElementById("MainText").classList.add('is-three-quarters');
            document.getElementById("MainText").classList.add('column');
            document.getElementById("MainText").classList.remove('px-5');
            persist_tocState( 'open');
        }
        else {
            document.getElementById("TOC").classList.add('is-hidden');
            document.getElementById("page-nav").classList.add('is-hidden');
            document.getElementById("mobile-nav").classList.add('is-hidden');
            document.getElementById("MainText").classList.remove('is-three-quarters');
            document.getElementById("MainText").classList.remove('column');
            document.getElementById("MainText").classList.add('px-5');
            persist_tocState( 'closed' );
        }
    }
    var setTocState = function ( state ) {
        if (document.getElementById("TOC") == null) { return };
        if ( state === 'closed') {
            document.getElementById("TOC").classList.add('is-hidden');
            document.getElementById("page-nav").classList.add('is-hidden');
            document.getElementById("mobile-nav").classList.add('is-hidden');
            document.getElementById("MainText").classList.remove('is-three-quarters');
            document.getElementById("MainText").classList.remove('column');
            document.getElementById("MainText").classList.add('px-5');
            document.getElementById("navbar-toc-toggle").checked = false;
        }
        else {
            document.getElementById("TOC").classList.remove('is-hidden');
            document.getElementById("page-nav").classList.remove('is-hidden');
            document.getElementById("mobile-nav").classList.remove('is-hidden');
            document.getElementById("MainText").classList.add('is-three-quarters');
            document.getElementById("MainText").classList.add('column');
            document.getElementById("MainText").classList.remove('px-5');
            document.getElementById("navbar-toc-toggle").checked = true;
        }
    };
    document.addEventListener('DOMContentLoaded', function () {
        // initialise if localStorage is set
        let theme = persisted_theme();
        if ( theme ) {
            theme = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
            change_theme(theme);
            persist_theme(theme);
        }
        let tocState = persisted_tocState();
        if ( tocState == null ) {
            setTocState( 'open' )
        }
        else {
            setTocState( tocState );
            persist_tocState( tocState );
        }
        // Add listeners
        // Get all "navbar-burger" elements
        const $navbarBurgers = Array.prototype.slice.call(document.querySelectorAll('.navbar-burger'), 0);
        // Check if there are any navbar burgers
        if ($navbarBurgers.length > 0) {
            // Add a click event on each of them
            $navbarBurgers.forEach(el => {
                el.addEventListener('click', () => {
                    // Get the target from the "data-target" attribute
                    const target = el.dataset.target;
                    const $target = document.getElementById(target);
                    // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
                    el.classList.toggle('is-active');
                    $target.classList.toggle('is-active');
                });
            });
        };
        // initialise window state
        document.getElementById('changeTheme').addEventListener('click', function () {
            let theme = persisted_theme() === 'light' ? 'dark' : 'light';
            change_theme(theme);
            persist_theme(theme);
        });
        if (document.getElementById("navbar-toc-toggle") !== null ) {
            document.getElementById("navbar-toc-toggle").addEventListener('change', function() {
                matchTocState( this.checked )
            });
            document.getElementById('toc-tab').addEventListener('click', function () { swap_toc_index('','toc') });
            document.getElementById('index-tab').addEventListener('click', function () { swap_toc_index('','index') });
            document.getElementById('mtoc-tab').addEventListener('click', function () { swap_toc_index('m','toc') });
            document.getElementById('mindex-tab').addEventListener('click', function () { swap_toc_index('m','index') });
            originalTOC = document.getElementById('toc-menu').getHTML();
            originalIndex = document.getElementById('index-menu').getHTML();
            document.getElementById("page-nav-search").addEventListener('keyup', function (event) {
                filtersearch(event, 'toc-menu', 'index-menu', 'page-nav')
            });
            document.getElementById("mobile-nav-search").addEventListener('keyup', function (event) {
                filtersearch(event, 'mtoc-menu', 'mindex-menu', 'mobile-nav')
            });
        }
    });
    function filtersearch(event, toc,index,nav) {
        document.getElementById(toc).innerHTML = originalTOC;
        document.getElementById(index).innerHTML = originalIndex;
        var searchText = event.srcElement.value.toLowerCase();
        if (searchText.length === 0) return;
        var menuListElements = document.getElementById(nav).querySelectorAll('.toc-item, .index-section');
        var matchingListElements = Array.from(menuListElements).filter(function (item) {
            var el;
            if ( item.classList.contains('toc-item') ) {
                el = item.querySelector('a');
            } else {
                el = item.querySelector('.index-entry')
            }
            var listItemHTML = el.innerHTML;
            var fuzzyRes = fuzzysort.go(searchText, [listItemHTML])[0];
            if (fuzzyRes === undefined || fuzzyRes.score <= 0) {
                return false;
            }
            var res = fuzzyRes.highlight('<b>','</b>');
            if (res !== null) {
                el.innerHTML = res;
                return true;
            } else {
                return false;
            }
        });
        menuListElements.forEach(function(elem){elem.classList.add('is-hidden')});
        matchingListElements.forEach(function(elem){elem.classList.remove('is-hidden')});
    };
    function swap_toc_index(div, activate) {
        let disactivate = (activate == 'toc') ? 'index' : 'toc';
        document.getElementById( div + activate + '-tab').classList.add('is-active');
        document.getElementById( div + disactivate + '-menu').classList.add('is-hidden');
        document.getElementById( div + disactivate + '-tab').classList.remove('is-active');
        document.getElementById( div + activate + '-menu').classList.remove('is-hidden');
    }
    SCRIPT
}
method raku-webs-scss {
    q:to/SCSS/;
    /*! Styling for Raku doc-website */
    $heading: #A30031;
    $family-secondary: "Lato", BlinkMacSystemFont, -apple-system, "Segoe UI", "Roboto", "Oxygen", "Ubuntu", "Cantarell", "Fira Sans", "Droid Sans", "Helvetica Neue", "Helvetica", "Arial", sans-serif;
    $size-3: 2rem;
    $size-4: 1.5rem;
    $size-5: 1.25rem;
    $size-6: 1rem;
    $size-7: 0.75rem;
    $weight-medium: 500;
    $weight-bold: 700;
    $weight-semibold: 600;
    $scheme-main-bis: var(--bulma-background-active);
    $border: hsl(221, 14%, 86%);
    /* Raku page template */
    .raku-webs.title {
        color: $heading;
        text-align: center;
        margin-bottom: $size-3;
    }
    .raku-webs.subtitle {
        text-align: center;
        margin-top: $size-5;
    }
    .heading > a {
        color: $heading
    }
    // Raku page headings
    .raku-webs-h1 {
      font-size: 1.375rem; // 22px
      font-weight: $weight-medium;
      padding: 0.35rem;
      text-align: center;
      margin-top: $size-7;
      margin-bottom: 1rem;
      background: $scheme-main-bis;
      border: 1px solid $border;
      border-bottom: 3px solid $heading;
      scroll-margin-top: 4.625rem;
    }
    .raku-webs-h2 {
      font-size: 1.375rem; // 22px
      font-weight: $weight-medium;
      padding: 0.25rem;
      margin-top: $size-7;
      margin-bottom: 1rem;
      border-bottom: 3px solid $heading;
      scroll-margin-top: 4rem;
    }
    .raku-webs-h3 {
      font-size: $size-5; // 20px
      font-weight: $weight-medium;
      margin-top: $size-7;
      margin-bottom: 1rem;
      scroll-margin-top: 4rem;
    }
    .raku-webs-h4 {
      font-size: $size-6;
      font-weight: $weight-medium;
      margin-bottom: 1rem;
      scroll-margin-top: 4rem;
    }
    .raku-webs-h5 {
      font-size: 0.875rem;
      font-weight: $weight-medium;
      margin-bottom: 1rem;
      scroll-margin-top: 3rem;
    }
    .raku-webs-h6 {
      font-size: $size-7;
      font-weight: $weight-semibold;
      margin-bottom: 1rem;
      scroll-margin-top: 3rem;
    }
    a.raku-webs-anchor {
      font-size: 0.9em;
      text-decoration: none;
      visibility: hidden;
      vertical-align: super;
      &:hover {
        color: var(--bulma-link);
      }
    }
    .raku-webs-h1:hover a.raku-webs-anchor, .raku-webs-h2:hover a.raku-webs-anchor, .raku-webs-h3:hover a.raku-webs-anchor, .raku-webs-h4:hover a.raku-webs-anchor, .raku-webs-h5:hover a.raku-webs-anchor, .raku-webs-h6:hover a.raku-webs-anchor {
      visibility: visible;
      padding-left: 5px;
    }
    nav.raku-webs.panel {
        padding-top: 1.5em;
    }
    span.code {
        background-color: var(--bulma-border-weak);
        border-radius: 5px;
    }
    span.Elucid8-ui {
        margin-left:0.5em;
        margin-right:0.5em;
    }
    .tooltip {
      position: relative;
      display: inline-block;
    }
    .tooltip .tooltiptext {
      visibility: hidden;
      width: 100%;
      background-color: #555;
      color: #fff;
      text-align: center;
      border-radius: 6px;
      padding: 5px 0;
      position: absolute;
      z-index: 1;
      top: 125%;
      right: 0;
      margin-left: -60px;
      opacity: 0;
      transition: opacity 0.3s;
    }
    .tooltip:hover .tooltiptext {
      visibility: visible;
      opacity: 1;
    }

    .navbar.raku-webs {
        background: var(--bulma-background-active);
    }

    .raku-webs .navbar-item {
        color: var(--bulma-text);
        text-shadow: -0.1px 0 var(--bulma-link), 0 0.1px var(--bulma-link), 0.1px 0 var(--bulma-link), 0 -0.1px var(--bulma-link);
        &.is-selected {
            color: var(--bulma-background);
        }
    }

    #Camelia { max-height: 2.75em; }
    .navbar-tm-logo {
        position: absolute;
        z-index: 35;
        top: 0.35rem;
        right: -0.35rem;
        font-size: 0.75rem;
    }
    .raku-webs.index-section {
        margin-left: calc(( var(--level) - 1 ) * 1rem);
        &[data-index-level="1"] {
            text-shadow: 1px 1px orange;
        }
        > a.index-ref {
            margin-left: calc(var(--level) * 1rem);
            display:block;
            width:auto;
            white-space:normal;
        }
    }
    /* Hopepage title */
    .raku-webs {
        .hero-body {
            background: linear-gradient(180deg, #051A33 0.2%, #3F103A 1%, #9F0046 82.29%, #B3004F 100%);
            mix-blend-mode: normal;
            .title,.subtitle {
                color: white;
            }
        }
        .card-content .icon.is-large {
            height: 6rem;
            width: 6rem;
            font-size: 96px;
        }
        .links-block .icon.is-large {
            height: 6rem;
            width: 6rem;
            font-size: 96px;
        }
        .card .button {
          width: 200px;
        }
        .card-home {
          box-shadow: unset !important;
        }
    }
    SCSS
}
method chyron-scss {
    q:to/CHYRON/;
    // Chyron Toggle checkbox
    label.chyronToggle input#navbar-toc-toggle {
        opacity: 0;
        height: 0;
        width: 0;
    }
    label.chyronToggle span.checkmark {
        top: 1rem;
        position: relative;
        cursor: pointer;
    }
    label.chyronToggle input[type="checkbox"]{
        position: absolute;
        opacity: 0;
        cursor: pointer;
        height: 0;
        width: 0;
    }
    label.chyronToggle span.checkmark::before {
        content: '[\21e8';
        color: grey;
        font-weight: 800;
        line-height: 0.5rem;
        font-size: 1.75rem;
        margin-right: 0.25rem;
        width: 3rem;
        display: inline-block;
    }
    label.chyronToggle:hover span.checkmark::before {
        content: '[ \21e8';
    }
    label.chyronToggle input[type="checkbox"]:checked + .checkmark::before {
        content: '[ \21e6';
    }
    label.chyronToggle:hover input[type="checkbox"]:checked + .checkmark::before {
        content: '[\21e6';
    }
    CHYRON
}
method toc-scss {
    q:to/TOC/;
    #page-nav {
        width: 25%;
        position: fixed;
    }
    #page-nav .panel-block .toc {
        overflow-y:scroll;
        height:65vh;
    }
    #page-nav .panel-block .index {
        overflow-y:scroll;
        height:65vh;
    }
    .main-footer {
        z-index: 1;
        position: relative;
    }
    .toc-item {
        &:hover {
            background: var(--bulma-background);
        }
        a {
            text-decoration:none;
            color: var(--bulma-text);
        }
    }
    TOC
}
# additions assuming bulma classes
method bulma-additions-scss {
    q:to/GENERAL/;
    .content p + ul.item-list { margin-top: 0; }
    // .content p:not( ul.item-list ) { margin-bottom: 0; }
    .content p + ol.item-list { margin-top: 0; }
    // .content p:not( ol.item-list ) { margin-bottom: 0; }
    .delta:hover { border: var(--bulma-border-hover) 1px solid; }
    .navbar-start { margin-bottom: 1rem; }
    GENERAL
}