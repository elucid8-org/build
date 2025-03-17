%(
    :repository-store<repos>,
    :repo-data-file<repo-data-file>, # file containing information about each file in repo
        # together with the link to the files for editing
    repositories => %(
        raku-docs-en => %(
            repo-name => 'Raku/doc',
            source-entry => '/docs',
            destination => 'en',
            description => 'documentation of the Raku language',
        ),
        rakudoc-en => %(
            repo-name => 'Raku/RakuDoc-GAMMA',
            source-entry => '/',
            destination => 'en/language',
            description => 'Rakudoc specification document',
            :ignore('README',),
        ),
        doc-website => %(
            destination => 'en',
            description => 'website sources',
            repo-name => '',
            source-entry => 'sources/en',
        )
    ),
)
