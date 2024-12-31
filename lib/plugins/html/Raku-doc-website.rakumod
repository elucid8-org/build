use v6.d;
use RakuDoc::Render;

unit class Elucid8::Plugin::HTML::Raku-Doc-Website;
has %.config =
    :name-space<RDWebsite>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    :js([self.js-text,3],),
;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-templates( $.templates, :source<UISwitcher plugin> );
    $rdp.add-data( %!config<name-space>, %!config );
}
method js-text {
    '// in development'
}
method templates {
    %(#| head-block, what goes in the head tab
        head-block => -> %prm, $tmpl {
            my %g-data := $tmpl.globals.data;
            # handle css first
            qq:to/HEAD/
            <title>{%prm<title>}</title>
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
        #| navigation bar at top of page
        navigation-bar => -> %prm, $tmpl {
            qq:to/BLOCK/
            <nav class="navbar is-fixed-top" role="navigation" aria-label="main navigation">
                <div class="navbar-brand">
                    <figure class="navbar-item is-256x256">
                        <a href="/index.html">
                        <img class="is-rounded" src="https://avatars.githubusercontent.com/u/58170775">
                        </a>
                    </figure>
            <span style="color:red;font-weight:900;">UIS</span>
                    <a role="button" class="navbar-burger" aria-label="menu" aria-expanded="false" data-target="pageNavigation">
                      <span aria-hidden="true"></span>
                      <span aria-hidden="true"></span>
                      <span aria-hidden="true"></span>
                      <span aria-hidden="true"></span>
                    </a>
                </div>
                <div id="pageNavigation" class="navbar-menu">
                    <div class="navbar-start">
                        <label class="chyronToggle">
                          <input id="navbar-toc-toggle" type="checkbox" />
                          <span class="checkmark"> </span>
                        </label>
                    </div>
                    <div class="navbar-end">
                        <div class="navbar-item">
                            <button id="changeTheme" class="button">Change theme</button>
                        </div>
                    </div>
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
                        <a id="mtoc-tab">Table of Contents</a>
                        <a id="mindex-tab">Index</a>
                      </p>
                        <aside id="mtoc-menu" class="panel-block">
                        { %prm<rendered-toc>
                            ?? %prm<rendered-toc>
                            !! '<p>No Table of contents for this page</p>'
                        }
                        </aside>
                        <aside id="mindex-menu" class="panel-block is-hidden">
                        { %prm<rendered-index>
                            ?? %prm<rendered-index>
                            !! '<p>No Index for this page</p>'
                        }
                        </aside>
                    </nav>
                </div>
            </nav>
            BLOCK
        },
    )
}