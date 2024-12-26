
# Build a website from current directory

	The Build component for the Elucid8 framework

----

## Table of Contents

<a href="#SYNOPSIS">SYNOPSIS</a>   
<a href="#Assumptions">Assumptions</a>   
<a href="#Configuration">Configuration</a>   
&nbsp;&nbsp;- <a href="#All_configuration_keys">All configuration keys</a>   
<a href="#Credits">Credits</a>   
<a href="#VERSION_0">VERSION</a>   


<div id="SYNOPSIS"></div>

## SYNOPSIS
<span class="para" id="12dfbaf"></span>The component is part of the `Elucid8` distribution and is installed once installed as 


```
    zef install Elucid8
```
<span class="para" id="9bab2e6"></span>The utility `elucid8-build` will generate a static website according to the [configuration](Configuration) in the Current Working Directory (CWD).

<div id="Assumptions"></div>

## Assumptions
<span class="para" id="e7ea0bd"></span>The Build component of Elucid8 assumes the following structure. 


```
sandpit                      # a test bed for a web site built with elucid8
    - config/                 # contains the website configuration
    - L10N/                  # contains the dictionaries from the canonical to derived languages
    - sources/               # Only directories containing language sources permitted here
      - canonical/          # RakuDoc content in canonical language
      - xx/                  # content in language with code xx
      - xx-YY/               # regional content in language with code xx-YY
```
<span class="para" id="48e6de8"></span>All names in the structure, except for `config/`, may be modified by changing fields in the files in `config/`. 

<span class="para" id="d16aa57"></span>The name of the **__config/__** directory may be changed by setting the `--config` option to `elucid8-build`. For example, if the canonical language is Mandarin, and the word used to mean 'config' is `布局`, then 


```
elucid8-build --config=<布局>
```
<span class="para" id="5d77cc3"></span>will set the configuration directory *布局*. This will be called the *localised config*. 

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
        L10N => 'lleoliad',
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

----

## <div id=""> </div>
 | **Key name** | **Value** | **Description** |
| :---: | :---: | :---: |
 | L10N | L10N | the directory containing Translation information |
 | sources | sources | content as RakuDoc sources, sub-directories are for content by language |
 | canonical | canonical | sub-directory of sources containing content, only sub-dir that needs defining in the config file |
 | extensions | <rakudoc rakumod> | an array of file extensions containing source |
 | quiet | False | output runtime progress information |
 | with-only | () | a list of strings or regexes, matching filenames only will be rendered (useful for debugging) |
<div id="Credits"></div>

## Credits
Richard Hainsworth, aka finanalyst




<div id="VERSION"></div><div id="VERSION_0"></div>

## VERSION
 <div class="rakudoc-version">v0.1.0</div> 



----

----

Rendered from docs/README.rakudoc/README at 19:32 UTC on 2024-12-26

Source last modified at 19:30 UTC on 2024-12-26

