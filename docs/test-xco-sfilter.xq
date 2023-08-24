import module namespace sf="http://www.parsqube.de/ns/xco/string-filter"
at 'xco-sfilter.xqm';

declare variable $s external := 'foo bar';
declare variable $sfilter external := 'fo*';

let $csfilter := sf:compileStringFilter($sfilter)
let $result := sf:matchesStringFilter($s, $csfilter)
return
    <result s="{$s}" sfilter="{$sfilter}" result="{$result}">{
        $csfilter
    }</result>