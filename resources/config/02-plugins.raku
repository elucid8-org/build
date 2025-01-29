%(
    rakuast-rakudoc-plugins => <
      Hilite
      ListFiles
      Graphviz FontAwesome Latex LeafletMaps
      SCSS
    >,
    plugins => <
        UISwitcher
        Raku-Doc-Website
        AutoIndex
        SiteData
    >,
    pre-file-render => %(
        SiteData => 'initialise',
    ),
    post-file-render => %(
#        SiteData => 'extract-snippets',
    ),
    post-all-content-files => %(
        SiteData => 'gen-composites',
    )
)