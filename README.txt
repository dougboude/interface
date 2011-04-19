Interface.cfc is a ColdFusion component whose purpose in life is to allow for much greater flexibility when implementing interfaces. It addresses the two primary downfalls of Adobe ColdFusion's implementation of interfaces:
1. Method names must be explicitly declared;
2. Only public methods can be 'policed' by ColdFusion interfaces

Interface.CFC's highlights:
    1. Very non-intrusive. Simply extend Interface.cfc within a component or within the most base component of any heredity chain;
    2. Rather than die on the first error encountered, Interface.cfc will analyze the entire function collection at once and throw a comprehensive error detailing EVERYTHING it found in violation of the rules;
    3. The rules is an easy to read array that is self-explanatory and highly expandable.
    4. Rules are triggered when a function name matches a regular expression in the "name" key for a given rule set.

	
Interface.CFC utilizes an array of "rules", matching a rule set to a method using a regular expression instead of an explicit name. A sample rule set is as follows:
<cfscript>
  stRules = [
  {
   name = "^format(?!Value).+?",
   args = {
    targetValue = {
     type = "string",
     required = "true"
    }
   },
   access = "private",
   returntype = "string"
  },
  {
   name = "^validate(?!Value).+?",
   args = {
    targetValue = {
     type = "string",
     required = "true"
    }
   },
   access = "private",
   returntype = "boolean"
  }
 ];
 return stRules;
</cfscript>

USAGE
To use Interface.CFC:
1. Create the rules array within the getRules method of Interface.CFC;
2. Make the most base component in the chain (or the component being validated, if there's only one) extend Interface.CFC (<component extends="Interface"....>")
3. Execute the "validateInterface()" method in the pseudo-constructor area of the topmost component that is to be validated, like so:

<cfcomponent extends="myBaseComponent">
 <cfset validateInterface() />
 
 <cffunction name="init" ....</cffunction>
 ....
</cfcomponent>

USEFUL LINKS
Detailed blog post on Interface.CFC: http://www.dougboude.com/blog/1/2011/04/Picking-Up-Where-Interfaces-Fail.cfm
Detailed API Documentation: http://jbase.masonclaims.com/interface.cfc?method=getDocumentation
