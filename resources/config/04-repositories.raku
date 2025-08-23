%(
    :repository-store<repos>,
    :repository-info-file<repo-info.rakuon>,
    repositories => %(
        rakudoc => %(
            repo-name => 'Raku/RakuDoc-GAMMA',
            description => 'Rakudoc specification document',
            languages => %(
                en => %(
                    source-entry => 'compliance-document',
                    destination => 'language',
                    :select('rakudociem-ipsum',),
                ),
            ),
        ),
        'self' => %( # meaning this repository
            repo-name => 'elucid8-org/sandpit',
            description => 'website sources',
            languages => %(
                en => %(
                    source-entry => 'site-sources/en/',
                ),
            ),
        ),
    ),
)
