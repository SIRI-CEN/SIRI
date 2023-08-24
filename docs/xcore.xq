(:
 : xcore.xq - command-line interface of the XSD Content Reporter (XCORE)
 :)
import module namespace cr="http://www.parsqube.de/ns/xco/comp-reporter"
at "xco-comp-reporter.xqm";

import module namespace ci="http://www.parsqube.de/ns/xco/check-input"
at "xco-check-input.xqm";

import module namespace cu="http://www.parsqube.de/ns/xco/custom"
at "xco-custom.xqm";

import module namespace dg="http://www.parsqube.de/ns/xco/debug"
at "xco-debug.xqm";

import module namespace fu="http://www.parsqube.de/ns/xco/file-util"
at "xco-file-util.xqm";

import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
at "xco-namespace.xqm";

import module namespace sr="http://www.parsqube.de/ns/xco/schema-resolver"
at "xco-schema-resolver.xqm";

import module namespace dm="http://www.parsqube.de/ns/xco/domain"
    at "xco-domain.xqm";

import module namespace u="http://www.parsqube.de/ns/xco/util"
at "xco-util.xqm";

declare variable $report external := 'edesc';         (: def | desc | rdesc | edesc | contab | tree :)
declare variable $fnamesExcluded external := ('DATEXIISchema.xsd', 'OJP_deprecated.xsd');
declare variable $dir external := ();
declare variable $dnamesExcluded external := ();
declare variable $xsd external := (); (: '/projects/sbb/ojp/OJP.xsd'; :)
declare variable $odir external := ();
declare variable $ofile external := ();
declare variable $domains external := ();
declare variable $custom external := ();
declare variable $forEachDomain as xs:boolean? external := false(); 

declare variable $uri external := (); (: '/projects/sbb/ojp/OJP.xsd'; :)
declare variable $skipAnno as xs:boolean? external := ();
declare variable $skipAtts as xs:string? external := ();
declare variable $keepAtts as xs:string? external := ();
   
    (: Default value of customization path: 'custom.xml' in the folder containing this module :)
declare variable $enames external := ();
declare variable $anames external := ();
declare variable $tnames external := ();
declare variable $gnames external := ();
declare variable $hnames external := ();
declare variable $ens external := ();
declare variable $ans external := ();
declare variable $tns external := ();
declare variable $gns external := ();
declare variable $hns external := ();
declare variable $global as xs:boolean external := true();
declare variable $edescReport external := ();
declare variable $edescReportDir external := ();
declare variable $activeDomains external := ();
declare variable $debugDir external := ();
declare variable $debugFilter external := ();

(: If no name filter is used: set default name filters :)
let $nonames := empty(($enames, $anames, $tnames, $gnames, $hnames))
let $enames := ('*'[$nonames], $enames)[1]
let $anames := ('*'[$nonames], $anames)[1]
let $tnames := ('*'[$nonames], $tnames)[1]
let $gnames := ('*'[$nonames], $gnames)[1]
let $hnames := ('*'[$nonames], $hnames)[1]

let $activeDomains := $activeDomains ! tokenize(.)
let $dirNorm := $dir ! u:normalizeUri(., ())
let $odirNorm := $odir ! u:normalizeUri(., ())
let $customNorm := $custom ! u:normalizeUri(., ())
let $domainType := $domains
let $preliminaryOptions := 
    map{
        'dir': $dirNorm,
        'odir': $odirNorm,
        'domains': $domainType,
        'activeDomains': $activeDomains
    }
let $uris :=
    if ($dir) then file:descendants($dirNorm)[ends-with(., '.xsd')]
                   [not(file:name(.) = $fnamesExcluded)]
                   [not(
                       some $dname in tokenize($dnamesExcluded) satisfies
                         let $regex := u:literalToRegex($dname)
                         return matches(., '[/\\]'||$regex||'[/\\]', 'i'))]                   
    else $uri
let $_DEBUG := trace(($dnamesExcluded, '-')[1], '*** Dnames excluded:   ')    
let $_DEBUG := trace(count($uris), '*** Count(input XSDs): ')   
(: let $_DEBUG := trace($uris, '### URI: ') :)
let $schemas := sr:resolveSchemas($uris) => u:addLocalTypeIds()  
let $schemaDict := map:merge($schemas/map:entry(base-uri(.) ! u:normalizeUri(., ()), .))
let $customElem := cu:compileCustom($customNorm, $schemas, $preliminaryOptions)   
let $domainsElem := $customElem//domains
let $ofileNorm := if (not($ofile)) then () else
    let $fileName := $ofile ! file:name(.)
    return string-join(($odirNorm, $report, $fileName), '/')
let $nsmap := ns:getTnsPrefixMap($schemas, $customElem)
(: skipAnno - default dependent on report type :)
let $skipAnno := 
    if ($skipAnno) then $skipAnno 
    else if ($report eq 'contab') then false() 
    else false()

let $origReportType := $report
let $reportType := if ($report eq 'tree') then 'edesc' else $report
(: Folder containing intermediate edesc reports :)
let $edescReportDirDynamic :=
    if ($edescReportDir) then ()
    else if ($reportType ne 'contab') then ()
    else $odirNorm||'/edesc'
let $options := map{'skipAnno': $skipAnno,
                    'skipAtts': $skipAtts,
                    'keepAtts': $keepAtts,
                    'custom': $customElem,
                    'forEachDomain': $forEachDomain,
                    'domains': $domainsElem,
                    'domainType': $domainType,
                    'schemas': $schemaDict,
                    'nsmap': $nsmap,
                    'dir': $dirNorm,
                    'odir': $odirNorm,                    
                    'ofile': $ofileNorm,
                    'reportType': $reportType,
                    'edescReport': $edescReport,
                    'edescReportDir': $edescReportDir,
                    'edescReportDirDynamic': $edescReportDirDynamic,
                    'withEnumDict': false(),
                    'deepResolve': $origReportType eq 'tree'
                   }
let $options := dg:SET_DEBUG_OPTIONS($debugDir, $debugFilter, $options)
(: Use debugFilter custom=yes,domains=yes in order to get downloads of the
 : compiled custom file and the compiled domains :)
let $_WDEBUG := dg:WRITE_FILE($domainsElem, 'DOMAINS.xml', 'domains', 'yes', $options)
let $_WDEBUG := dg:WRITE_FILE($customElem, 'CUSTOM.xml', 'custom', 'yes', $options)                   
let $_CRDIR := (
    if (not($odirNorm)) then ()
    else if (file:exists($odirNorm)) then()
    else file:create-dir($odirNorm),
    if (not($ofileNorm)) then ()
    else 
       let $ofileDir := $ofileNorm ! fu:getParentPath(.)
       return
           if (file:exists($ofileDir)) then()
           else file:create-dir($ofileDir)
)    
let $_COPY := fu:copyCssFile($options)
let $_CHECK := ci:checkInput($reportType, $dir, $xsd, $odir, $ofile, $domains, $custom)

let $reportDoc := cr:reportComps($reportType,
    $enames, $anames, $tnames, $gnames, $hnames, 
    $ens, $ans, $tns, $gns, $hns, 
    $global, $schemas, $options)
return $reportDoc


