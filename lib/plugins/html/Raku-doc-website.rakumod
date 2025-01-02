use v6.d;
use RakuDoc::Render;
use RakuDoc::PromiseStrings;

unit class Elucid8::Plugin::HTML::Raku-Doc-Website;
has %.config =
    :name-space<RDWebsite>,
	:version<0.1.0>,
	:license<Artistic-2.0>,
	:credit<finanalyst>,
	:authors<finanalyst>,
    ui-tokens => %(
        :TOC<Table of Contents>,
        :NoTOC<No Table of contents for this page>,
        :ChangeTheme<Change Theme>,
        :Index<Index>,
        :NoIndex<No Index for this page>,
        :FileSource<Source file:>,
        :SourceModified<Source last modified:>,
        :Time( 'eval' ~ q|{ sprintf( "Rendered at %02d:%02d UTC on %s", .hour, .minute, .yyyy-mm-dd) with now.DateTime }| ),
    )
;
method enable( RakuDoc::Processor:D $rdp ) {
    $rdp.add-templates( $.templates, :source<Raku-doc-website plugin> );
    $rdp.add-data( %!config<name-space>, %!config );
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
                        { $tmpl('ui-switch-button', %( %prm, :classes('navbar-item has-dropdown is-hoverable') )) }
                        <div class="navbar-item">
                            <button id="changeTheme" class="button"><span class="Elucid8-ui" data-UIToken="ChangeTheme">ChangeTheme</span></button>
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
        page-navigation => -> %prm, $tmpl {
            qq:to/SIDEBAR/;
            <nav class="panel is-hidden-mobile" id="page-nav">
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
                            <span class="Elucid8-ui" data-UIToken="FileSource">Source</span><span class="footer-field">{%prm<source-data><name>}
                        </div>
                        <div class="level-item">
                            <span class="Elucid8-ui" data-UIToken="Time">Time</span>
                        </div>
                        <div class="level-item">
                            <span class="Elucid8-ui" data-UIToken="SourceModified">SourceModified</span>{(sprintf( " %02d:%02d UTC, %s", .hour, .minute, .yyyy-mm-dd) with %prm<source-data><modified>.DateTime)}
                        </div>
                    </nav>
                </div>
                { qq[<div class="section"><div class="container px-4 warnings">{%prm<warnings>}</div></div>] if %prm<warnings> }
            </footer>
            FOOTER
        },
    )
}