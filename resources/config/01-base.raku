%(
    :favicon-file('')       # directory/filename to be used as the site's favicon.ico. must be in appropriate format
                            # if this is not set, then the Elucid8 favicon in the resources/ directory is used
    :site-sources<site-sources>, # rakudoc source files not in a repo
    :local-lib<local-lib>,  # directory containing local plugins
    :file-data-name<file-data.rakuon>,
                            # name of file that contains all the ToC, index, and other state data
                            # for each source file that has been rendered. Intended to avoid
                            # re-rendering every source when only some have been modified
    :canonical<en>,         # sub-dir of sources with canonical content
    :misc<misc>,            # directory with information and favicon files
    :ui-dictionary<ui-dictionary.rakuon>, # name of dictionary with ui token and translations
    :extensions<rakudoc rakumod>, # possible extensions for files with RakuDoc source
    :!quiet,                # no trace if True, over-rides trace
    :trace(''),             # a list of plugins to toggle debug output, none if empty
                            # typically, a plugin or stage will emit an entrance message
    :with-only(),           # only render files in this list, all files if empty
    :ignore(),              # ignore files in this list
    :publication<publication>, # directory where rendered HTML files are placed
    :landing-page<index>,   # name of file where the web-site starts
    :landing-title(         # title for the auto-generated landing page
                    'Website contents'),
    :landing-subtitle(      # subtitle = description of auto-generated landing page
                    'Choose the language to start' ),
    :glues( {               # files that should be rendered after all the others
                            # the files are in the form :filename( n ), where n >= 1
                            # n is rendered before n+1
        } ),
    :deprecated( %(         # mapping of deprecated urls to
                            # newer equivalents
                            # it will be server centric
         )
    ),
    :regenerate,            # regenerate the entire build from scratch
)