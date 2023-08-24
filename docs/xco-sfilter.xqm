module namespace sf="http://www.parsqube.de/ns/xco/string-filter";

(:
 :    C o m p i l e    s t r i n g    f i l t e r
 :    ===========================================
 :)

(:~
 : Compiles a string filter into a structured representation.
 : The representation is a <stringFilter> element with the following child elements:
 : include: a set of regexes and/or strings or substrings to be matched
 : exclude: a set of regexes and/or strings or substrings which must not be matched
 :
 : @param sfilter a string filter string
 : @return a map representing the string filter
 :)
declare function sf:compileStringFilter(
                    $sfilter as xs:string?) 
        as element(stringFilter)? {
    let $itemsAndFlags := sf:splitStringIntoItemsAndFlags($sfilter, '#')
    let $flags := $itemsAndFlags[1]    
    let $items := subsequence($itemsAndFlags, 2)
    
    (: global flags :)
    let $ignoreCase := not(contains($flags, 'c'))
    let $patternIsRegex := contains($flags, 'r')
    let $addAnchors := not(contains($flags, 'A')) 
    
    let $patterns := $items ! replace(., '^\s+|\s+$', '')[string()]
    return if (empty($patterns)) then () else
    
    let $patternsPlus := $patterns[not(starts-with(., '~'))]
    let $patternsMinus := $patterns[starts-with(., '~')] ! substring(., 2)
    return 
        if (empty(($patternsPlus, $patternsMinus))) then () else
        <stringFilter text="{$sfilter}">{
            if (empty($patternsPlus)) then () else
            <include>{sf:compileSfPatternSet(
                $patternsPlus, $ignoreCase, $patternIsRegex, $addAnchors)
            }</include>,
            if (empty($patternsMinus)) then () else
            <exclude>{sf:compileSfPatternSet(
                $patternsMinus, $ignoreCase, $patternIsRegex, $addAnchors)
            }</exclude>
        }</stringFilter>
};

(:~
 : Translates a list of string filter patterns into a structured
 : representation. A pattern is a glob pattern or a regular expression.
 : The structured representation is a map.
 :
 : @param patterns a list of patterns
 : @param ignoreCase if true, regex matching ignores case
 : @param patternIsRegex if true, patterns are interpreted as regular
 :   expressions, otherwise as glob patterns
 : @param addAnchors if true, by default glob patterns are translated
 :   into regular expressions with anchors indicating the begin and
 :   end of the string; the default can be overridden by flags 'a'
 :   (add anchors) and 'A' (do not add anchors). 
 : @return a map with possible entries 'empty', 'regexes', 'flags', 
 :   'strings', 'substrings'. 
 :)
declare function sf:compileSfPatternSet($patterns as xs:string*, 
                                        $ignoreCase as xs:boolean?,
                                        $patternIsRegex as xs:boolean?,
                                        $addAnchors as xs:boolean?)
        as element()* {
    let $literals := 
        if ($patternIsRegex) then () else $patterns[not(matches(., '[@*?\\]'))]
    let $literalsEff := 
        if (not($ignoreCase)) then $literals else $literals ! lower-case(.)
    (: each regex is described by a map with keys 'expr' and 'flags' :)
    let $regexes := 
        for $pattern in $patterns[not(. = $literals)]
        let $regexAndFlags := 
            sf:patternToRegexAndFlags($pattern, $ignoreCase, $patternIsRegex, $addAnchors)
        return <regex expr="{$regexAndFlags[1]}" flags="{$regexAndFlags[2]}"/>
         
    return (
        <regexes>{$regexes}</regexes>,
        if (empty($literals)) then () else
        
        let $key := if ($addAnchors) then 'strings' else 'substrings'
        return
            element {$key} {
                attribute ignoreCase {$ignoreCase},
                $literalsEff ! <s>{.}</s>}
   )
};

(:~
 : Maps a pattern string to a regex string and a flags string.
 : The pattern string may contain flags, separted from the 
 : pattern itself by a '@'.
 :
 : Supported flags: 
 : a/A - add anchors / do not add anchors
 : r/R - pattern is regex / is not regex
 : c/C - evaluate case-sensitively / not case-sensitively
 :
 : The parameters $ignoreCase, $patternIsRegex, $addAnchors
 : provide default values for flags.
 :
 : The return value consists of the regex and optional regex flags,
 : which are either the empty string or 'i' meaning case-insensitive 
 : evaluation.
 :)
declare function sf:patternToRegexAndFlags(
                    $pattern as xs:string, 
                    $ignoreCase as xs:boolean?, 
                    $patternIsRegex as xs:boolean?, 
                    $addAnchors as xs:boolean?)
        as xs:string+ {
    let $exprAndFlags :=
        if (not(contains($pattern, '@'))) then $pattern (: no flags :)
        else            
            let $exprAndFlags := sf:splitStringAtDoubleEscapableChar($pattern, '@')
            let $expr := $exprAndFlags[1]
            let $flags := $exprAndFlags[2]            
            return ($expr, $flags)
    let $expr := $exprAndFlags[1]
    let $flags := $exprAndFlags[2]
    let $regexAndFlags :=
        (: no flags :)
        if (not($flags)) then
            let $regex := 
                if ($patternIsRegex) then $expr 
                else $expr ! sf:globToRegex(., 'A'[not($addAnchors)])
            let $regexFlags := 'i'[$ignoreCase]                    
            return ($regex, $regexFlags) 
        else  
            let $patternIsRegexEff :=
                if ($flags ! matches(., 'r', 'i')) then contains($flags, 'r')
                else $patternIsRegex
            let $addAnchorsEff := 
                if ($flags ! matches(., 'a', 'i')) then not(contains($flags, 'A')) 
                else $addAnchors 
            let $ignoreCaseEff :=
                if ($flags ! matches(., 'c', 'i')) then not(contains($flags, 'c'))
                else $ignoreCase 
            let $regexFlags := 'i'[$ignoreCaseEff]
            let $regexExpr := 
                if ($patternIsRegexEff) then $expr 
                else $expr ! sf:globToRegex(., 'A'[not($addAnchorsEff)])
            return ($regexExpr, $regexFlags)    
    return $regexAndFlags            
};

(:
 :    M a t c h    s t r i n g    f i l t e r
 :    =======================================
 :)

(:~
 : Matches a string against a string filter. The filter has been constructed
 : by function f:compileStringFilter.
 :
 : @param string the string to match
 : @param filter the compiled string filter
 : @return true or false, if the string matches, does not match, the filter
 :) 
declare function sf:matchesStringFilter($string as item(),                                               
                                        $filter as element(stringFilter)?)
        as xs:boolean {
    if (empty($filter)) then true() else        
    let $include := $filter/include
    let $exclude := $filter/exclude
    return
        (empty($include) or $include/sf:matchesSfPatternSet($string, .)) and
        (empty($exclude) or not($exclude/sf:matchesSfPatternSet($string, .)))        
};

(:~
 : Matches a string against a string filter pattern set. The pattern set
 : is represented by an element with the following child elements:
 : - regexes: contains a sequence of <regex> elements, each with attributes @expr and @flags
 : - strings: contains a sequence of strings, wrapped in <s> elements;
 :     matching requires that the test string is equal to one of these; 
 :     @ignoreCase=true/false indicates case-sensitivity
 : - substrings: contains a sequence of strings, wrapped in <s> elements; 
 :     matching requires that the test string contains one of these; 
 :     @ignoreCase=true/false indicates case-sensitivity
 :
 : @param string the string to match
 : @param stringFilter a compiled string filter 
 : @return true if the string filter is matched, false otherwise
 :)
declare function sf:matchesSfPatternSet($string as xs:string, 
                                        $patternSet as element())
        as xs:boolean {
    let $stringEff := if ($patternSet/(strings, substring)/@ignoreCase = 'true') then lower-case($string) else $string
    return
        $patternSet/strings/* = $stringEff
        or (some $sstr in $patternSet/substrings/* satisfies 
            contains($stringEff, $sstr))
        or (some $r in $patternSet/regexes/regex satisfies 
            matches($string, $r/@expr, $r/@flags))
};

(:
 :    U t i l i t y    f u n c t i o n s
 :    ==================================
 :)

(:~
 : Splits a string into items and flags. The optional flags are separated
 : from the items by a # character. Doubled # characters are interpreted as
 : literal characters which do not separate items and flags.
 :
 : The item text is tokenized into items separated by whitespace (default) 
 : or one of the characters ,;:/. A non-whitespace separator is assumed if 
 : contained by the flag string.
 :
 : Example: "foo bar zoo"
 : => flags="", three items="foo", "bar", "zoo"
 :
 : Example: "foo##bar#c"
 : => flags="c", one item="foo#bar"
 :
 : Example: "foo bar, zoo #,c"
 : => flags=",c", two items="foo bar", "zoo"
 :
 : Example: "foo bar; zoo #c;"
 : => flags="c;", two items="foo bar", "zoo"
 :
 : Example: "foo:bar, zoo #:"
 : => flags=":", two items="foo", "bar, zoo"
 :
 : @param string the string to be split
 : @return a sequence of strings; the first one represents the flags, which
 :   may be a zero-length string; all following items represent the items
 :   extracted from the string
 :)
declare function sf:splitStringIntoItemsAndFlags($string as xs:string, 
                                                 $char as xs:string) 
        as xs:string+ {
    let $concatAndFlags := sf:splitStringAtDoubleEscapableChar($string, $char)        
    let $concat := $concatAndFlags[1]
    let $flags := $concatAndFlags[2]
    return
        if (tokenize($flags) = ('fulltext', 'ftext', 'ft')) then ($flags, $concat)
        else
        
    let $sep := 
        if (not(matches($flags, '[,;:/]'))) then () else
            replace($flags, '^.*([,;:/]).*', '$1') ! substring(., 1, 1)
    return (
        $flags,
        if ($sep) then tokenize($concat, '\s*'||$sep||'\s*') else tokenize($concat))
};

(:~
 : Returns the substrings preceding and following the first occurrence of a
 : character ($char) which is not escaped by repeating it. (In other words:
 : the first occurrence of $char which is either not repeated or repeated an 
 : uneven number of times.) If the string does not contain the character or 
 : any occurrence is repeated an even number of times), the original string 
 : and a zero-length string are returned.
 : 
 : The first substring returned is edited by replacing any doubled occurrence 
 : of the character with a single occurrence. (Note that the second
 : substring is not edited.)
 :
 : @param string the string to be analyzed
 : @param char the character separating the substrings
 : @return sequence of two strings: the string preceding and 
 :   the string following the character
 :)
declare function sf:splitStringAtDoubleEscapableChar(
                    $string as xs:string, 
                    $char as xs:string)
        as xs:string+ {
    if (not(contains($string, $char))) then ($string, '')
    else if (not(contains($string, $char||$char))) then (
            substring-before($string, $char), substring-after($string, $char))
    else        
        let $patternBefore := '^('||$char||$char||'|[^'||$char||'])+'
        return 
            let $before := replace($string, '('||$patternBefore||').*', '$1')
            let $after := substring($string, string-length($before) + 2)
            return ($before ! replace(., $char||$char, $char), $after)
};        

(:~
 : Maps a glob pattern to a regular expression.
 :
 : @param glob a glob pattern
 : @param flags flags controlling the evaluation;
 
 : @return the equivalent regular expession
 :)
declare function sf:globToRegex($glob as xs:string, $flags as xs:string?)
        as xs:string {
    let $addAnchors := not(contains($flags, 'A')) return
    
    $glob        
    ! replace(., '\\s', ' ')
    ! replace(., '[.+|\\(){}\[\]\^$]', '\\$0')        
    ! replace(., '\*', '.*')
    ! replace(., '\?', '.')
    ! (if ($addAnchors) then concat('^', ., '$') else .)
};
