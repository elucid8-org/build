%(
    # plugins in the order to be applied
    # templates in later plugins over-ride or can use those in earlier ones
    # elucid8-build prefixes names here with 'RakuDoc::Plugin::HTML::'
    plugins => <
        RakuDoc::Plugin::HTML::Hilite
        RakuDoc::Plugin::HTML::ListFiles
        RakuDoc::Plugin::HTML::Graphviz
        RakuDoc::Plugin::HTML::FontAwesome
        RakuDoc::Plugin::HTML::Latex
        RakuDoc::Plugin::HTML::LeafletMaps
        RakuDoc::Plugin::HTML::SCSS
        RakuDoc::Plugin::HTML::Bulma
        Elucid8::Plugin::HTML::Favicon
        Elucid8::Plugin::HTML::UISwitcher
        Elucid8::Plugin::HTML::AutoIndex
        Elucid8::Plugin::HTML::SiteMap
    >,
    # callable in the class will expect arguments as documented here
    setup => (# sequence not hash because order can matter
    # callable-name ( %config )
        Favicon => 'move-favicon',
    ),
    pre-file-render => (# sequence not hash because order can matter
    # callable-name ( $rdp, $lang, $fn, $ast )
    ),
    post-file-render => (# sequence not hash because order can matter
    # callable-name ( $rdp, $rendered-html )
    ),
    post-all-content-files => (# sequence not hash because order can matter
    # callable-name ( $rdp, $lang, $to, %config )
    ),
    post-all-files => ( # sequence because order matters
    # callable-name ( $rdp, %site-config )
        SiteMap => 'create-site-map',
    )
)
