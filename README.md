
# Build a website from current directory

	The Build component for the Elucid8 framework

----

## Table of Contents

<a href="#SYNOPSIS">SYNOPSIS</a>   
<a href="#Assumptions">Assumptions</a>   
<a href="#Configuration">Configuration</a>   
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
    - sources/
      - canonical/          # RakuDoc content in canonical language
      - xx/                     # content in language with code xx
      - xx-YY/               # regional content in language with code xx-YY
```
<span class="para" id="48e6de8"></span>All names in the structure, except for `config/`, may be modified by changing fields in the files in `config/`. 

<div id="Configuration"></div>

## Configuration
<span class="para" id="1079711"></span>A directory called `config/` is required in the CWD. 

<div id="Credits"></div>

## Credits
Richard Hainsworth, aka finanalyst




<div id="VERSION"></div><div id="VERSION_0"></div>

## VERSION
 <div class="rakudoc-version">v0.1.0</div> 



----

----

Rendered from docs/README.rakudoc/README at 12:42 UTC on 2024-12-25

Source last modified at 12:38 UTC on 2024-12-25

