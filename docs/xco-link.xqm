(:
 : Functions calculating link addresses.
 :)
module namespace ln="http://www.parsqube.de/ns/xco/link";

import module namespace co="http://www.parsqube.de/ns/xco/constants"
    at "xco-constants.xqm";

import module namespace dg="http://www.parsqube.de/ns/xco/debug"
    at "xco-debug.xqm";

import module namespace dm="http://www.parsqube.de/ns/xco/domain"
    at "xco-domain.xqm";

import module namespace fu="http://www.parsqube.de/ns/xco/file-util"
    at "xco-file-util.xqm";
    
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
    at "xco-namespace.xqm";

import module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description"
    at "xco-stype-description.xqm";

import module namespace sf="http://www.parsqube.de/ns/xco/string-filter"
    at "xco-sfilter.xqm";

import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Returns the link address for a type definition.
 :
 : @param domain the optional domain containing the link source
 : @param targetName qualified name of the target
 : @param typeDesc type description of the target
 : @return link address
 :)
declare function ln:getTypeLinkRef($domain as element()?,
                                   $targetName as xs:QName,
                                   $typeDesc as xs:string?,
                                   $options as map(xs:string, item()*))
        as xs:string? {
    if (ns:isQNameBuiltin($targetName)) then ()        
    else if (not($typeDesc ! sd:isTypeDescriptionEnumDesc(.)) 
             or not($options?withEnumDict)) then 
        ln:getLinkRef($domain, 'type', $targetName, $options)
    else
    
    let $hrefFragment := '#enum.'||$targetName
    return
        if (not($domain)) then
            let $sourcePath := dm:getReportPath('contab', (), $options)
            let $targetPath := dm:getReportPartPath('contab', 'enum-dict', (), $options)            
            let $relPath := fu:getRelPath($sourcePath, $targetPath)
            return $relPath||$hrefFragment
        else
        
    let $fnFindComp := $dm:findComps('type')
    let $ns := namespace-uri-from-QName($targetName)
    let $lname := local-name-from-QName($targetName)
    return
        let $sourceDomainPath := dm:getReportPath('contab', $domain, $options) 
        let $sourceDomainParentPath := $sourceDomainPath ! fu:getParentPath(.) 
        let $targetDomain := $domain/../*[$fnFindComp(., $ns, $lname)][1]
        let $targetDomain := ($targetDomain, $domain)[1]  
            (: A broken link, unless the targetDomain has been found :)
        let $targetDomainPath := dm:getReportPartPath('contab', 'enum-dict', $targetDomain, $options)            
        let $relTargetDomainPath := fu:getRelPath($sourceDomainParentPath, $targetDomainPath)
        return $relTargetDomainPath||$hrefFragment
};

(:~
 : Returns the href string to be used when referencing a 
 : schema component from a schema in a given domain.
 :
 : @param domain the domain to which the link source belongs
 : @param targetKind the kind of component to be referenced
 :     (element/attribute/type/group/attributeGroup)
 : @return the string to be used as @href value 
 :)
declare function ln:getLinkRef($domain as element()?,
                               $targetKind as xs:string,
                               $targetName as xs:QName,
                               $options as map(xs:string, item()*))
        as xs:string? {
    let $ns := namespace-uri-from-QName($targetName)        
    return if ($ns eq $co:URI_XSD) then () else
    
    let $hrefFragment := '#'||$targetKind||'.'||$targetName      
    return if (not($domain)) then $hrefFragment else
    
    let $sourceDomainPath := dm:getReportPath('contab', $domain, $options)
    let $sourceDomainParentPath := $sourceDomainPath ! fu:getParentPath(.)
    let $fnFindComp := $dm:findComps($targetKind)
    let $lname := local-name-from-QName($targetName)
    let $inSameDomain := $domain/$fnFindComp(., $ns, $lname)  
    return
        if ($inSameDomain) then $hrefFragment else
        
        let $targetDomain := $domain/../*[$fnFindComp(., $ns, $lname)][1]
        let $targetDomain := ($targetDomain, $domain)[1]  
            (: A broken link, unless the targetDomain has been found :)
        let $targetDomainPath := dm:getReportPath('contab', $targetDomain, $options)
        let $relTargetDomainPath := fu:getRelPath($sourceDomainParentPath, $targetDomainPath)
        return $relTargetDomainPath||$hrefFragment
};

(:~
 : Returns the href string to be used when referencing a 
 : local type definition.
 :
 : @param typeId the type Id 
 : @return the string to be used as @href value 
 :)
declare function ln:getLocalTypeLinkRef(
                               $domain as element()?,
                               $typeId as xs:string,
                               $tdesc as xs:string?,
                               $options as map(xs:string, item()*))
        as xs:string? {
    if (not($tdesc ! sd:isTypeDescriptionEnumDesc(.))) then 
        '#local-type.'||$typeId
    else 
        ln:getLocalEnumTypeLinkRef($domain, $typeId, $options)
};

(:~
 : Returns the href string to be used when referencing a 
 : local enum type definition. 
 : Important - if domains are used, the link source is assumed 
 : in the same domain as the link target.
 :
 : @param typeId the type Id 
 : @return the string to be used as @href value 
 :)
declare function ln:getLocalEnumTypeLinkRef(
                               $domain as element()?,
                               $typeId as xs:string,
                               $options as map(xs:string, item()*))
        as xs:string? {
    let $domainFile := $domain/dm:getReportPartPath('contab', 'enum-dict', ., $options) 
    return $domainFile||'#local-enum.'||$typeId
};
