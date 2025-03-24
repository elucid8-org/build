
# Build a website from current directory

	The Build component for the Elucid8 framework

----

## Table of Contents

<a href="#SYNOPSIS">SYNOPSIS</a>   
<a href="#Assumptions">Assumptions</a>   
<a href="#Plugins">Plugins</a>   
<a href="#Render_workflow">Render workflow</a>   
<a href="#Configuration">Configuration</a>   
&nbsp;&nbsp;- <a href="#All_configuration_keys">All configuration keys</a>   
<a href="#Credits">Credits</a>   
<a href="#VERSION_0">VERSION</a>   


<div id="SYNOPSIS"></div>

## SYNOPSIS
<span class="para" id="67e8bd0"></span>The component is part of the `Elucid8` distribution and is installed as 


```
    zef install Elucid8-build
```
<span class="para" id="9bab2e6"></span>The utility `elucid8-build` will generate a static website according to the [configuration](Configuration) in the Current Working Directory (CWD). 

<span class="para" id="192f918"></span>If the CWD is empty, `elucid8-build install` will create a default structure 

<span class="para" id="7e52a22"></span>If the CWD has a custom (localised) config file, which may be any localised name, and the contents have the keys required (in English) but with localised values (eg. Kostom), then `elucid8-build --config=Kostom --install` then the subdirectories will be localised as well. 

<span class="para" id="5ca62c5"></span>Elucid8 may be used in two ways: 



1. <span class="para" id="3d08365"></span>All the RakuDoc sources are in the main website directory, under the `sources` subdirectory.  

2. The RakuDoc sources may be located in various repositories.  

<span class="para" id="cdacb20"></span>For the second scenario, the `gather-sources` utility is used first. See [Gather and Build](Build-Gather.md) for more information. 

<span class="para" id="a2ec6fd"></span>Once the website has been built, the `run-locally` utility will serve the HTML files, and can be browsed in a browser as `localhost:3000`. (The port can be changed in the plugins-configuration config). 

<span class="para" id="6db1721"></span>Run `elucid8-build -h` to get information on command line flags. 

<span class="para" id="38b318e"></span>Subsequent calls to `elucid8-build` will only rebuild modified source files, but see *-f* and *-with-only*

<div id="Assumptions"></div>

## Assumptions
<span class="para" id="e7ea0bd"></span>The Build component of Elucid8 assumes the following structure. 


```
sandpit                      # a test bed for a web site built with elucid8
    - config/                 # contains the website configuration
    - misc/                  # contains the dictionaries from the canonical to derived languages
    - sources/               # Only directories containing language sources permitted here
      - canonical/           # RakuDoc content in canonical language, which is en by default
      - xx/                  # content in language with code xx
      - xx-YY/               # regional content in language with code xx-YY
```
<span class="para" id="48e6de8"></span>All names in the structure, except for `config/`, may be modified by changing fields in the files in `config/`. 

<span class="para" id="809d5b5"></span>The name of the **__config/__** directory may be changed by setting the `--config` option to `elucid8-build`. For example, if the canonical language is Mandarin, and the term used to mean 'config' is `布局`, then 


```
elucid8-build --config=<布局>
```
<span class="para" id="5d77cc3"></span>will set the configuration directory *布局*. This will be called the *localised config*. 

<div id="Plugins"></div>

## Plugins
<span class="para" id="016ad6d"></span>The following HTML plugins are available: 



1. <span class="para" id="8602167"></span>[UISwitcher](UISwitcher.md)  

2. <span class="para" id="ad545ea"></span>SiteMap - creates `sitemap.xml` which can be read by robots  

3. <span class="para" id="4ca8437"></span>AutoIndex - creates a `landing-page` file for the whole website from all glue files  

<span class="para" id="bced907"></span>Each website can have its own plugins, stored in `local-lib` 


<div id="Render workflow"></div><div id="Render_workflow"></div>

## Render workflow
<span class="para" id="9b89ead"></span>For each human language (h-language), the sources files in the appropriately named sub-directory of `sources` (or local equivalent), each generate a separate web page. 

> <span class="para" id="4435ebe"></span>Elucid8 is being designed for large websites and currently these are not optimally viewed using the *single page* paradigm. In the future, this view may change, in which case, each source will generate a section of the page.

<span class="para" id="f76fda4"></span>The source files in an h-language directory are of two sorts: 


<span style="font-weight: 600; font-style: italic">1.&nbsp;content</span>

&nbsp;&nbsp;<span style="background-color: lightgrey;">sources that are the basis of the website. They may contain explicit links to other pages. </span>

<span style="font-weight: 600; font-style: italic">2.&nbsp;glue</span>

&nbsp;&nbsp;<span style="background-color: lightgrey;">sources that are automatically generated to contain links to web pages generated by content (and possibly other glue) sources. </span>

<span style="font-weight: 600; font-style: italic">3.&nbsp;info</span>

&nbsp;&nbsp;<span style="background-color: lightgrey;">sources that contain site information not to be included in the search, such License or about. </span>

<span style="font-weight: 600; font-style: italic">4.&nbsp;landing-page</span>

&nbsp;&nbsp;<span style="background-color: lightgrey;">the name of the web page that is the default for a browser. By default it is auto-generated from the TITLEs and SUBTITLEs of the glue files in each h-language. </span>

<span class="para" id="08dbff7"></span>Consequently, 



1. content web pages must be generated first  

2. info web pages must be generated next  

3. glue web pages must be generated after all content sources  

4. glue pages must be rendered in an explicit order  

5. if no content sources have changed since the last rendering, then glue web pages do not need to be re-generated, unless a glue source has itself been modified.  

<span class="para" id="d06fe5e"></span>In addition, 



1. <span class="para" id="3991f70"></span>a change in a canonical content source should trigger a change of style in the [equivalent content file](Canonical&lt;->derived links)  

2. editing of derived sources will be more frequent than editing of the canonical sources  

<span class="para" id="f14308f"></span>For simplicity and initial development, the following are required: 



1. glue sources must be exist for each language (no super-language glue sources)  

2. the filename of each glue source must be the same in each directory  

3. content sources are implicitly assigned a generation order of zero  

4. the name and generation order of each glue source is defined in the config directory  

<span class="para" id="2b5f0c3"></span>Consequently, the render order is as follows: 



1. the canonical language sources must be rendered first  

2. a content source is only re-generated if:  

2.1. the force flag is True  

2.2. there is no existing rendered file with the same name  

2.3. the content source is newer than the generate file  

3. if a canonical content source is re-generated, the equivalent source in all of the h-language directories must be re-generated too  

4. if a source (content or glue) is regenerated, all the glue files at the next generation order must be re-generated  

5. <span class="para" id="495250c"></span>if no sources are regenerated at some level, then the glue sources at the next generation order do not need to be regenerated **unless** the glue source itself is modified. (This implies that changes cascade up the regeneration order)  

6. the sources in each derived language are rendered in an unspecified order of languages  

7. a content source is only re-generated if:  

7.1. the force flag is True  

7.2. the equivalent canonical source was rendered in this build cycle  

7.3. there is no existing rendered file with the same name  

7.4. the content source is newer than the generated file  

8. the glue sources are generated as per the canonical glue sources  

9. <span class="para" id="af7e8b1"></span>the **landing-page** is generated  

9.1. <span class="para" id="7475ea6"></span>By default, a web page with the name **landing-page***.html* is auto-generated  

9.2. <span class="para" id="cdc148c"></span>If a source with the name **landing-page***.rakudoc* exists in the **__sources__** directory, it is used to generate the landing page. A custom block is defined to add the glue contents that are auto-generated.  

<div id="Configuration"></div>

## Configuration
<span class="para" id="a656b92"></span>A directory called `config/` (or its preconfigured alternative) is required in the CWD. 

<span class="para" id="4bc7a56"></span>The **__config/__** directory follows the conventions set out in the distribution `raku-config`. 

<span class="para" id="8bd20b2"></span>If a *localised config* has been specified, then one key must be called by the same name, and must contain a hash in which the key is a key of the default (English) *config* and the value is a string that is a key in the localised config. 

<span class="para" id="4a353e6"></span>If some of the keys in the default are missing in the localised config, then the value of the default config is used. 

<span class="para" id="e636be1"></span>This allows for some or all of the configuration to be specified in a canonical language other than English. 

<span class="para" id="affbede"></span>The full set of [configuration keys](All configuration keys) and their defaults are in English. 

<span class="para" id="10bca45"></span>For example, suppose we have a web-site where Welsh is the canonical language and the *config* file is partially in Welsh. Suppose further that the build command is: 


```
    elucid8-build --config=ffurfwedd
```
<span class="para" id="ccd1235"></span>Then in this case, the directory `ffurfwedd/` should contain a file, typically named *01-ffurfwedd.raku*, with the content: 


```
    ffurfwedd => %(
        sources => 'ffynhonnell',
        canonical => 'gofyddebol',
        Misc => 'lleoliad',
    )
```
<span class="para" id="67ecc08"></span>Then the web-site would need to be structured as follows 


```
<web-site directory>/
|- config/
|- lleoliad/
|- ffurfwedd/
    |- 01-ffurfwedd.raku
|- ffynhonnell/
    |- gofyddebol/
    |- en-GB/
```
<span class="para" id="6192fe5"></span>The **config** directory and its contents are needed because the localised config is incomplete. 

<span class="para" id="a2b1488"></span>If **all** the mandatory config keys are defined in the *localised config*, and all the keys have values, then the default can be removed. 


<div id="All configuration keys"></div><div id="All_configuration_keys"></div>

### All configuration keys
<span class="para" id="56d1481"></span>The following is a list of all the mandatory config keys and their default values. 


 | **Key name** | **Value** | **Description** |
| :---: | :---: | :---: |
 | misc | misc | the directory containing global information for translation, and file-data, repo-info |
 | sources | sources | content as RakuDoc sources, sub-directories are for content by language. See repositories |
 | canonical | canonical | sub-directory of sources containing content, only sub-dir that needs defining in the config file |
 | extensions | &lt;rakudoc rakumod> | an array of file extensions containing source |
 | quiet | False | output runtime progress information |
 | with-only | () | a list of strings or regexes, matching filenames only will be rendered (useful for debugging) |
 | ignore | () | list of strings or regexes, matching files will not be rendered |
 | publication | 'publication' | directory relative to CWD where HTML and assets are rendered |
 | landing-page | 'index' | the name of the page that is the default route for a web-site |
 | &nbsp; | <span class="para" id="b662593"></span>The plugins needed are more easily kept in a separate file, typically `02-plugins.raku` | &nbsp; |
 | plugins | &lt;Bulma Hilite ListFiles> | <span class="para" id="7ed8fe0"></span>plugins attached to the Rendering engine ***packaged with rakuast-rakudoc-render*** |
 | plugins | plugins ,= &lt;Graphviz FontAwesome Latex LeafletMaps> | <span class="para" id="4722e84"></span>custom blocks ***packaged with rakuast-rakudoc-render*** |
 | plugins | plugins ,= 'UISwitcher', | <span class="para" id="335106d"></span>Adds multi-lingual UI ***packaged with Elucid8*** |
 | plugins | plugins ,= 'SCSS', | <span class="para" id="5f9c227"></span>must be last plugin enabled, converts SCSS in other plugins to CSS ***packaged with rakuast-rakudoc-render*** |
<div id="Credits"></div>

## Credits
Richard Hainsworth, aka finanalyst




<div id="VERSION"></div><div id="VERSION_0"></div>

## VERSION
 <div class="rakudoc-version">v0.1.0</div> 



----

----

Rendered from docs/README.rakudoc/README at 20:27 UTC on 2025-03-24

Source last modified at 20:26 UTC on 2025-03-24

