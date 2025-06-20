(:
 : Functions evaluating customization data.
 :)
module namespace cu="http://www.parsqube.de/ns/xco/custom";

import module namespace dm="http://www.parsqube.de/ns/xco/domain"
  at 'xco-domain.xqm';
import module namespace u="http://www.parsqube.de/ns/xco/util"
  at 'xco-util.xqm';

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Maps the customization document to an enhanced representation.
 :
 : @param path file path of the customization document
 : @schemas the schemas to be evaluated
 : @return enhanced customization document
 :)
declare function cu:compileCustom($path as xs:string?,
                                  $schemas as element(xs:schema)+,
                                  $options as map(xs:string, item()*)) {
    let $customElem := $path ! doc(.)/*                              
    return 
        if ($customElem) then 
            $customElem/cu:compileCustomREC(., $schemas, $options) ! u:prettyNode(.)
        else if (not($options?domains)) then ()
        else
            <custom>{
                dm:constructDomains((), $schemas, $options)
            }</custom>
};

(:~
 : Recursive helper function of `compileCustom`.
 :)
declare function cu:compileCustomREC($n as node(),
                                     $schemas as element(xs:schema)+,
                                     $options as map(xs:string, item()*))
        as node()* { 
    typeswitch($n)
    case document-node() return document {$n/node() ! cu:compileCustomREC(., $schemas, $options)}
    case element(domains) return ()    
    case element(custom) return
        element {node-name($n)} {
            $n/@* ! cu:compileCustomREC(., $schemas, $options),
            $n/node() ! cu:compileCustomREC(., $schemas, $options),
            dm:constructDomains($n/domains, $schemas, $options)
        }
    case element() return
        element {node-name($n)} {
            $n/@* ! cu:compileCustomREC(., $schemas, $options),
            $n/node() ! cu:compileCustomREC(., $schemas, $options)
        }
    default return $n
};

(:~ 
 : Returns the "title" of the XSD documentation as a whole. This title
 : is displayed above the TOC providing links to the documentation
 : resource. 
 :
 : The title is returned as a sequence of nodes.
 :
 : @param reportType the report type
 : @param custom customization element
 : @param options options controlling the processing
 : @return a sequence of nodes representing the title
 :)
declare function cu:systemTitleNodes($reportType as xs:string?,
                                     $custom as element()?,
                                     $options as map(xs:string, item()*))
        as node()+ {
    let $titleNodes := $custom/systemTitle/node()        
    return
        if (empty($titleNodes)) then text {'XSD documentation - overview'} 
        else $titleNodes
};

(:~ 
 : Returns the "title" of the XSD documentation as a whole. This title
 : is displayed above the TOC providing links to the documentation
 : resource. 
 :
 : The title is returned as a single string.
 :
 : @param reportType the report type
 : @param custom customization element
 : @param options options controlling the processing
 : @return a string representing the title
 :)
declare function cu:systemTitleString(
                                     $reportType as xs:string?,
                                     $custom as element()?,
                                     $options as map(xs:string, item()*))
        as xs:string {
    ($custom/systemTitle/string(.), 'XSD documentation - overview')[1]
};

(:~ 
 : Returns the "title" of an XSD, as used in the TOC of a report with a
 : given report type.
 :)
declare function cu:xsdTitle($schema as element(xs:schema),
                             $reportType as xs:string,
                             $domainId as xs:string?,
                             $custom as element()?)
        as xs:string {
    if (not($custom)) then 'Schema file: '||$schema/base-uri(.) ! file:name(.) else
    
    let $fnGetTitle := function($xsdTitlePref, $schema) {
        switch($xsdTitlePref)
        case 'singleSentenceAnno' return
            let $anno := ($schema/xs:annotation/xs:documentation)[1]
            where $anno
            return replace($anno, '(.*?)\.\s.*', '$1') 
        case 'firstSentenceAnno' return
            let $anno := $schema/xs:annotation/xs:documentation
            where $anno
            return replace($anno, '(.*?)\.\s.*', '$1') 
        case 'fileName' return
            'Schema file: '||$schema ! base-uri(.) ! file:name(.)
        default return ()
    }
    
    let $reportTypeElem := cu:_getReportTypeElem($custom, $domainId, $reportType)
    let $xsdTitle := $reportTypeElem/xsdTitle
    let $pref1 := $xsdTitle/@pref1/$fnGetTitle(., $schema)
    return if ($pref1) then $pref1 else
    let $pref2 := $xsdTitle/@pref2/$fnGetTitle(., $schema)
    return if ($pref2) then $pref2 else
    let $pref3 := $xsdTitle/@pref3/$fnGetTitle(., $schema)
    return if ($pref3) then $pref3 else
    'Schema file: '||$schema/base-uri(.) ! file:name(.)    
};

(:~
 : Returns the (possibly) customized name of a component, as used in a report 
 : with a given report type.
 :
 : @param name the original QName, as a string
 : @param componentKind the component kind (element, attribute, complexType, simpleType, group, attributeGroup) 
 : @param use main or sub, indicating if the component is the topic itself or referenced
 : @param reportType the type of the report to be produced
 : @param custom element defining customization
 : @return the lexical name to be used in the report
 :)
declare function cu:customComponentName($name as xs:string,
                                        $componentKind as xs:string,
                                        $use as xs:string,
                                        $reportType as xs:string,
                                        $domainId as xs:string?,                                        
                                        $custom as element())
        as xs:string {
    let $reportTypeElem := cu:_getReportTypeElem($custom, $domainId, $reportType)        
    let $nameElem := $reportTypeElem/nameEdit        
    let $compNameElem := $nameElem/comp[@kind eq $componentKind][@use eq $use]
    let $removePrefix := $compNameElem/@removePrefix
    let $replace := $compNameElem/@replace
    let $with := $compNameElem/@with
    (:
    let $_DEBUG :=
        if ($name ne 'ojp:AccessFeatureStatusEnumeration') then ()
        else trace(...)
     :)
    return
        let $cuname := $name
        let $cuname := if ($removePrefix = '*' 
                           or (some $p in $removePrefix satisfies starts-with($name, $p||':'))) 
                       then $cuname ! replace(., '^.+:', '')
                       else $cuname
        let $cuname := if ($compNameElem/@replace) then $compNameElem/replace($cuname, @replace, @with)
                       else $cuname
        return $cuname
};

(:~
 : Returns the relevant report type element defining the
 : report type related cusgtomization.
 :)
declare %private function cu:_getReportTypeElem(
                    $custom as element(custom), 
                    $domainId as xs:string?, 
                    $reportType as xs:string)
        as element(reportType)? {
    let $reportTypeElem :=
        if (not($domainId)) then () else
            $custom/domains/domain[@id eq $domainId]
                   /processing/reportTypes/reportType[@name eq $reportType]
    return if ($reportTypeElem) then $reportTypeElem else
    $custom/reportTypes/reportType[@name eq $reportType]
};
        