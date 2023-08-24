(:
 : xco-stype-description - functions creation simple type descriptions
 :)
module namespace sd="http://www.parsqube.de/ns/xco/simple-type-description";

import module namespace ed="http://www.parsqube.de/ns/xco/edesc"
    at "xco-edesc.xqm";
import module namespace ns="http://www.parsqube.de/ns/xco/namespace"
    at "xco-namespace.xqm";
import module namespace sf="http://www.parsqube.de/ns/xco/comp-finder"
    at "xco-comp-finder.xqm";
import module namespace u="http://www.parsqube.de/ns/xco/util"
    at "xco-util.xqm";

declare namespace z="http://www.parsqube.de/ns/xco/structure";

(:~
 : Maps a type name to a simple type description. If the type
 : name identifies a complex type with simple content, the
 : simple type used by the complex type is described.
 :
 : @param name a qualified type name
 : @param nsmap a map of namespace bindings 
 : @param schemas the schemas to be evaluated 
 : @param options options controlling the processing 
 : @return a type description, or the empty sequence if the name does not
 :   refer to a simple type or a complex type with simple content
 :)
declare function sd:typeNameToTypeDescription($name as xs:QName, 
                                              $nsmap as element(z:nsMap),
                                              $schemas as element(xs:schema)*,
                                              $options as map(xs:string, item()*))
        as xs:string? {
    if (ns:isQNameBuiltin($name)) then
        ns:normalizeQName($name, $nsmap) ! string()
    else
    
    let $typeDef := sf:findType($name, $schemas)
    let $stypeDef := u:extractSimpleType($typeDef, $schemas)
    where exists($stypeDef)
    return
        if ($stypeDef instance of xs:anyAtomicType) then
            sd:typeNameToTypeDescription($stypeDef, $nsmap, $schemas, $options)
        else
            let $edesc := ed:getExpandedCompDescs($stypeDef, $nsmap, $schemas, $options)
            let $tdesc := $edesc ! sd:edescToTypeDescription($edesc)
            return $tdesc
};

(:~
 : Maps a type definition to a simple type description. The empty sequence is 
 : returned unless the type definition is a simple type or a complex type with 
 : simple content.
 :
 : @param stypeTree extended descriptor of a simple type
 : @return the text of a description
 :)
declare function sd:typeDefToTypeDescription($type as element(), 
                                             $nsmap as element(z:nsMap),
                                             $schemas as element(xs:schema)*,
                                             $options as map(xs:string, item()*))
        as xs:string? {
    let $stype := u:extractSimpleType($type, $schemas)  
    return
        if ($stype instance of xs:anyAtomicType) then 
            sd:typeNameToTypeDescription($stype, $nsmap, $schemas, $options)
        else
    let $edesc := ed:getExpandedCompDescs($stype, $nsmap, $schemas, $options)
    let $tdesc := $edesc ! sd:edescToTypeDescription($edesc)
    return $tdesc
};

(:~
 : Maps an extended descriptor of a type definition to a textual description.
 :
 : @param stypeTree extended descriptor of a simple type
 : @return the text of a description
 :)
declare function sd:edescToTypeDescription($edesc as element())
        as xs:string {
    let $tdesc := sd:edescToTypeDescriptionREC($edesc)
    return $tdesc
};

(:~
 : Recursive helper function of `edescToTypeDescription`.
 :)
declare function sd:edescToTypeDescriptionREC($n as node())
        as xs:string? {
    let $result :=
    typeswitch($n)
    case element(z:simpleType) return
        $n/* ! sd:edescToTypeDescriptionREC(.)
    case element(z:annotation) return ()    
    case element(z:list) return
        let $itemType := $n/z:itemType
        let $itemTypeDesc :=
            if ($itemType/@z:name) then $itemType/@z:name/string()
            else $itemType/* ! sd:edescToTypeDescriptionREC(.)
        return
            'List('||$itemTypeDesc||')'
    case element(z:union) return
        let $memberDescs := $n/z:unionMember/* ! sd:edescToTypeDescriptionREC(.)
        return
            'Union('||string-join($memberDescs ! concat('{', ., '}'), ', ')||')'
    case element(z:faceted) return
        let $baseDesc := $n/z:baseType ! sd:edescToTypeDescriptionREC(.) 
        let $restrictions := $n/z:restrictions/z:restriction => sd:getRestrictionInfo()
        return
            $baseDesc||': '||$restrictions
    case element(z:baseType) return
        if ($n/@z:name) then $n/@z:name
        else $n/* ! sd:edescToTypeDescriptionREC(.)
    case element(z:builtinType) return $n/@z:name/string()
    case element() return ()
    default return ()
    return $result
};

(:~
 : Transforms a list of restrictions contained by an extended type
 : descriptor into a concise textual description.
 :)
declare function sd:getRestrictionInfo
                    ($restrictions as element(z:restriction)*) as xs:string? {
   if (empty($restrictions)) then () else

   let $length := for $f in $restrictions/z:length return concat('len=', $f/@z:value)
   let $minLength := max($restrictions/z:minLength/@z:value/xs:int(.))
   let $maxLength := min($restrictions/z:maxLength/@z:value/xs:int(.))
   let $minInclusive := max($restrictions/z:minInclusive/@z:value/sd:castToComparable(.))
   let $minExclusive := max($restrictions/z:minExclusive/@z:value/sd:castToComparable(.))
   let $maxInclusive := min($restrictions/z:maxInclusive/@z:value/sd:castToComparable(.))
   let $maxExclusive := min($restrictions/z:maxExclusive/@z:value/sd:castToComparable(.))

   let $totalDigits := $restrictions/z:totalDigits/@z:value/xs:int(.)
   let $totalDigits := if (empty($totalDigits)) then () 
                       else concat('totalDigits=', 
                           string-join(for $t in $totalDigits return string($t), ','))
   let $fractionDigits := $restrictions/z:fractionDigits/@z:value/xs:int(.)
   let $fractionDigits := if (empty($fractionDigits)) then () 
                          else concat('fractionDigits=', 
                              string-join(for $t in $fractionDigits return string($t), ','))
   let $minMax :=
      if (exists(($minInclusive, $minExclusive)) and 
          exists(($maxInclusive, $maxExclusive)))
      then
         let $lhs := if (exists($minInclusive) and not($minInclusive < $minExclusive))
                        then concat('[', $minInclusive)
                     else concat('(', $minExclusive)
         let $rhs := if (exists($maxInclusive) and not($maxInclusive > $maxExclusive))
                        then concat($maxInclusive, ']')
                     else concat($maxExclusive, ')')
         return concat('range=', $lhs, ',', $rhs)
      else if (exists($minInclusive) or exists($minExclusive)) then
         if (exists($minInclusive) and not($minInclusive < $minExclusive))
            then concat('value>=', $minInclusive)
         else concat('value>', $minExclusive)
      else if (exists($maxInclusive) or exists($maxExclusive)) then
         if (exists($maxInclusive) and not($maxInclusive > $maxExclusive))
            then concat('value<=', $maxInclusive)
         else concat('value<', $maxExclusive)
      else ()
   let $enums := string-join(
       for $r in $restrictions[z:enumeration][last()]/z:enumeration
       order by lower-case($r/@z:value)
       return $r/@z:value
       , '|')
   let $enums := $enums[string()] ! concat('enum=(', ., ')')
   let $patterns :=      
      string-join(
         $restrictions[z:pattern]/string-join(z:pattern/@z:value, ' OR ')
      , ' AND ')
   let $patterns := $patterns[string()] ! concat('pattern=#', ., '#')
   let $minMaxLength :=
      if (exists($minLength) and exists($maxLength)) then concat('len=', $minLength, '-', $maxLength)
      else if (exists($minLength)) then concat('minLen=', $minLength)
      else if (exists($maxLength)) then concat('maxLen=', $maxLength)
      else ()
   let $facets := (
      string-join(($length, $minMaxLength, $minMax, 
                   $totalDigits, $fractionDigits, 
                   $enums, $patterns), '; ')[string()],
      '(empty restriction)')[1]
   return $facets   
};

(:~
 : Determines if a given simple type description refers to an enum type.
 :
 : @param tdesc a simple type description
 : @return true or false
 :)
declare function sd:isTypeDescriptionEnumDesc($tdesc as xs:string?)
        as xs:boolean? {
    $tdesc ! contains(., 'enum=')        
};

(:~
 : Casts a string to a value comparable per < and >.
 :)
declare function sd:castToComparable($s as xs:string?)
      as item()? {
    if ($s castable as xs:date) then xs:date($s) 
    else if ($s castable as xs:dateTime) then xs:dateTime($s) 
    else if ($s castable as xs:time) then xs:time($s)      
    else if ($s castable as xs:double) then number($s)
    else if ($s castable as xs:decimal) then number($s)
    else if ($s castable as xs:boolean) then xs:boolean($s) ! number(.)
    else xs:untypedAtomic($s)    
};


