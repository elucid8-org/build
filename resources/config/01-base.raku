%(
    :sources<sources>,      #| directory root of rakudoc source files
    :canonical<en>,         #| sub-dir of sources with canonical content
    :L10N<L10N>,            #| directory with translation information
    :ui-dictionary<ui-dictionary.rakuon>, #| name of dictionary with ui token and translations
    :extensions<rakudoc rakumod>, #| possible extension of rakudoc source
    :!quiet,                #| no output is required if True
    :with-only(),           #| only render files in this list
    :ignore(),              #| ignore files in this list
    :destination<publication>, #| directory where rendered HTML files are placed
    :landing-page<index>,   #| name of file where the web-site starts
    :last(),                #| files that should be rendered after all the others
)