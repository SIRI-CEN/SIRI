(:
 : xco-comp-names - functions creating / evaluating a map of component names.
 : Names are grouped by component kind, and each kind is represented by a
 : map entry with a key corresponding to the kind.
 :
 : Keys: group, attributeGroup, element, attribute, type, localType.
 :
 : Names are qualified names, with the exception of local type names,
 : which are strings obtained from the @z:typeID attribute.
 :)
module namespace cn="http://www.parsqube.de/ns/xco/comp-names";

import module namespace cf="http://www.parsqube.de/ns/xco/comp-finder"
at "xco-comp-finder.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Maps a set of schema components to a map containing the component names.
 : Map keys are the component kinds, map values the qualified component names 
 : or, in the case of local type components, the @z:typeID values.
 :
 : @param comps schema components
 : @return a map of component names
 :)
declare function cn:getCompNames($comps as element()*)
        as map(xs:string, item()*) {
    let $fnCompName := function($comp) {$comp/@name/QName(string(ancestor::xs:schema/@targetNamespace), .)}        
    let $groups := $comps/self::xs:group[@name]/$fnCompName(.)
    let $attGroups := $comps/self::xs:attributeGroup[@name]/$fnCompName(.)
    let $elems := $comps/self::xs:element/$fnCompName(.)
    let $atts := $comps/self::xs:attribute/$fnCompName(.)
    let $types := $comps/(self::xs:simpleType, self::xs:complexType)[@name]/$fnCompName(.)
    let $localTypes := $comps/(self::xs:simpleType, self::xs:complexType)[not(@name)]/@z:typeID/string()
    return
        map:merge((
            map:entry('group', $groups)[exists($groups)],
            map:entry('attributeGroup', $attGroups)[exists($attGroups)],
            map:entry('element', $elems)[exists($elems)],
            map:entry('attribute', $atts)[exists($atts)],
            map:entry('type', $types)[exists($types)],
            map:entry('localType', $localTypes)[exists($localTypes)]
        ))
};

(:~
 : Merges two maps of component names into a single map.
 :
 : @param compNames1 a map of component names
 : @param compNames2 another map of component names
 : @return a map of component names
 :)
declare function cn:mergeCompNames($compNames1 as map(xs:string, item()*)?, 
                                   $compNames2 as map(xs:string, item()*)?)
        as map(xs:string, item()*) {
    let $groups := ($compNames1?group, $compNames2?group) => distinct-values()
    let $attributeGroups := ($compNames1?attributeGroup, $compNames2?attributeGroup) => distinct-values()
    let $elements := ($compNames1?element, $compNames2?element) => distinct-values()
    let $attributes := ($compNames1?attribute, $compNames2?attribute) => distinct-values()
    let $types := ($compNames1?type, $compNames2?type) => distinct-values()
    let $localTypes := ($compNames1?localType, $compNames2?localType) => distinct-values()
    return
        map:merge((
            map:entry('group', $groups)[exists($groups)],
            map:entry('attributeGroup', $attributeGroups)[exists($attributeGroups)],
            map:entry('element', $elements)[exists($elements)],
            map:entry('attribute', $attributes)[exists($attributes)],
            map:entry('type', $types)[exists($types)],
            map:entry('localType', $localTypes)[exists($localTypes)]
        ))
};

(:~
 : Returns a map of component names occurring in one map but not occurring in
 : a second map.
 :
 : @param compNames1 a map of component names
 : @param compNames2 another map of component names
 : @return a map of component names
 :)
declare function cn:compNamesExcept($compNames1 as map(xs:string, item()*), 
                                    $compNames2 as map(xs:string, item()*))
        as map(xs:string, item()*) {
    let $groups := $compNames1?group[not(. = $compNames2?group)] 
        => distinct-values()
    let $attributeGroups := $compNames1?attributeGroup[not(. = $compNames2?attributeGroup)]
        => distinct-values()    
    let $elements := $compNames1?element[not(. = $compNames2?element)]
        => distinct-values()    
    let $attributes := $compNames1?attribute[not(. = $compNames2?attribute)]
        => distinct-values()    
    let $types := $compNames1?type[not(. = $compNames2?type)]
        => distinct-values()    
    let $localTypes := $compNames1?localType[not(. = $compNames2?localType)]
        => distinct-values()    
    return
        map:merge((
            map:entry('group', $groups)[exists($groups)],
            map:entry('attributeGroup', $attributeGroups)[exists($attributeGroups)],
            map:entry('element', $elements)[exists($elements)],
            map:entry('attribute', $attributes)[exists($attributes)],
            map:entry('type', $types)[exists($types)],
            map:entry('localType', $localTypes)[exists($localTypes)]
        ))
};

(:~
 : Resolves qualified component names to the component elements.
 : 
 : The names are provided as a map with component kinds as keys (group, 
 : attributeGroup, element, attribute, type, local type) and a sequence of 
 : names as values.
 : 
 : The component elements are provided as a map with component kinds as keys
 : and a sequence of component elements as values.
 :
 : @param compNames qualified component names arranged in a map
 : @param schemas schema elements
 : @param terminate if true, a fatal error is raised if a component cannot be 
 :   found
 : @return a map with component kinds as keys and sequences of component
 :   elements as values
 :)
declare function cn:resolveCompNames($compNames as map(xs:string, item()*),
                                     $schemas as element(xs:schema)*,
                                     $terminate as xs:boolean?)
        as map(xs:string, item()*) {
    (: Function returning the components for the names of a particular component kind :)
    let $fnFindComps := function($kind, $compNames, $schemas, $fnFind) {
        let $names := $compNames($kind)
        for $name in $names 
        let $comp := $fnFind($name, $schemas)        
        return
            if (not($comp) and $terminate) then
                error(QName((), 'COMPONENT_NOT_FOUND'), 
                    'Cannot resolve '||$kind||' - '||
                    'name: '||$name)
            else $comp
    }
    return
    
    map:merge(
        for $key in $compNames ! map:keys(.)
        let $comps :=
            switch($key)
            case 'group' return $fnFindComps($key, $compNames, $schemas, cf:findGroup#2)
            case 'attributeGroup' return $fnFindComps($key, $compNames, $schemas, cf:findAttributeGroup#2)
            case 'element' return $fnFindComps($key, $compNames, $schemas, cf:findElement#2)
            case 'attribute' return $fnFindComps($key, $compNames, $schemas, cf:findAttribute#2)
            case 'type' return $fnFindComps($key, $compNames, $schemas, cf:findType#2)
            case 'localType' return $fnFindComps($key, $compNames, $schemas, cf:findLocalType#2)
            default return error()
        return map:entry($key, $comps)  
    )    
};