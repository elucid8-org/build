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
        DataTable
        Search
    >,
    pre-file-render => (# sequence not hash because order can matter
        SiteData => 'initialise',
    ),
    post-file-render => (# sequence not hash because order can matter
#        SiteData => 'extract-snippets',
    ),
    post-all-content-files => (# sequence not hash because order can matter
        SiteData => 'gen-composites',
        Search => 'prepare-search-data',
    )
)