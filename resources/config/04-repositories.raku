%(
    :repository-store<repos>,
    :repository-info-file<repo-info.rakuon>,
    repositories => %(
        rakudoc => %(
            repo-name => 'Raku/RakuDoc-GAMMA',
            description => 'Rakudoc specification document',
            languages => %(
                en => %(
                    source-entry => '/',
                    destination => 'language',
                    :select('rakudoc_v2',),
                ),
            ),
        ),
        'self' => %( # meaning this repository
            repo-name => 'elucid8-org/minimal',
            description => 'website sources',
            languages => %(
                en => %(
                    source-entry => 'site-sources/en/',
                ),
            ),
        ),
    ),
)
