%(
    :repository-store<repos>,
    repositories => %(
        raku-docs-en => %(
            repo-name => 'Raku/doc',
            source-entry => 'docs/',
            destination => 'en',
            description => 'documentation of the Raku language',
        ),
        rakudoc-en => %(
            repo-name => 'Raku/RakuDoc-GAMMA',
            source-entry => '/',
            destination => 'en/language',
            description => 'Rakudoc specification document',
        ),
        doc-website => %(
            destination => 'en',
            description => 'website sources',
            repo-name => '',
            source-entry => 'sources/en',
        )
    ),
)
