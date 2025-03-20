%(
    :repository-store<repos>,
    repositories => %(
        raku-docs => %(
            repo-name => 'Raku/doc',
            description => 'documentation of the Raku language',
            languages => %(
                en => %(
                    source-entry => '/docs',
                ),
            ),
        ),
        rakudoc => %(
            repo-name => 'Raku/RakuDoc-GAMMA',
            description => 'Rakudoc specification document',
            languages => %(
                en => %(
                    source-entry => '/',
                    destination => 'language/',
                    :select('rakudoc_v2',),
                ),
            ),
        ),
        'self' => %( # meaning this repository
            repo-name => 'Elucid8-sandpit',
            description => 'website sources',
            languages => %(
                en => %(
                    source-entry => 'site-sources/en',
                ),
            ),
        ),
    ),
)
