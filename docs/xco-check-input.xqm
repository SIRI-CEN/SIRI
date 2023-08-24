module namespace ci="http://www.parsqube.de/ns/xco/check-input";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
  at "xco-namespace.xqm";
import module namespace u="http://www.parsqube.de/ns/xco/util"
  at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

declare function ci:checkInput($report as xs:string?,
                               $dir as xs:string?,
                               $xsd as xs:string?,
                               $odir as xs:string?,
                               $ofile as xs:string?,                               
                               $domains as xs:string?,     
                               $custom as xs:string?)
        as empty-sequence() {
    let $customElem :=
        if (not($custom)) then ()
        else
            let $customPath := u:normalizeUri($custom, static-base-uri())
            return
                if (not(doc-available($customPath))) then
                    error((), '*** Error - custom file not valid XML; path: '||$customPath)
                else $customPath ! doc(.)
    let $customDomains := $customElem/domains
    return (
        if (not($ofile ! matches(., '[/\\]'))) then () else
            error((),
                'Invalid $ofile value ("'||$ofile||'") - must be a file name, not a path. Aborted.')
        ,
        if (not($ofile) or $odir) then () else
            error((),
                'An $ofile value must be accompanied by an $odir value. Aborted.')
        ,
        (: Report = contab: either custom domains, or odir, or ofile required :)
        if ($report ne 'contab') then () else
            if ($odir or $ofile or $domains or $customDomains) then () else
                error((),
                    'Report "contab" - either odir, or ofile, or domains, or custom domains '||
                    'must be specified. Aborted.')
                    
    )
};        
