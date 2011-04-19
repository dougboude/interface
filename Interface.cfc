<cfcomponent
	hint="I am used in place of a ColdFusion interface to validate the API of all objects that extend me.<br>
		To use me:
		<ul>
			<li>Create a validation rules array in my getRules method;</li>
			<li>make the most base component in any heredity chain of components extend me;</li>
			<li>In the topmost component in the chain that should have its API validated, execute the method 'validateInterface()' within the pseudo-constructor area</li>
		</ul>"
>

	
	<!--- walk through all of the methods I am aware of (which will include those in components that extend me)
	 and for each, see if it's name matches one of my rules. If the name rules match, inspect the function for additional rules (returntype, argument names, argument types, etc.)
	 --->
	 
	 <cffunction name="validateInterface" returntype="void" output="true" hint="I am the primary 'kickoff' method that is executed by the topmost component to have its API validated by me.">
	 	<cfscript>
			var stMetaData = getMetaData(this);
			//how many levels of component extension are we working with, excluding this one which should be at the very end of the chain?
			//var eLevels = getELevels(stMetaData);
			//for each level of inheritance, let's loop over the functions and try to match them against our rules
			var retval = validateFunctions(stMetaData);
			var msg = "";
			if(arraylen(retval) gt 0){
				msg = "<h2>ONE OR MORE FUNCTIONS ARE IN VIOLATION OF INTERFACE RULES</h2>";
				msg = msg & "<h4>#arrayToList(retval,"<br>")#</h4>";
				throw(msg);
			}
		</cfscript>
	 </cffunction>
	 
	 <cffunction name="validateFunctions" output="true" returntype="array" hint="I am the worker bee method that manages the actual validation. I am recursive in nature, so bow down to my awesomeness.">
	 	<cfargument name="stMetaData" type="struct" required="true" />
		
		<cfset var aFuncs = arguments.stMetaData.FUNCTIONS />
		<cfset var cName = arguments.stMetaData.NAME />
		<cfset var i = 1 />
		<cfset var status = [] />
		<cfset var message = [] />
		
		<cfloop from="1" to="#arraylen(aFuncs)#" index="i">
			<!--- for each function, does it match any of our name rules? --->
			<cfset fRules = nameMatch(aFuncs[i]['NAME']) />

			<cfif structcount(fRules) gt 0>
				<!--- if args rules were defined, validate those --->
				<cfif structkeyexists(fRules,"ARGS")>
					<cfset status = validateArgs(fRules,aFuncs[i],aFuncs[i]['NAME'],cName) />
					<cfif arraylen(status) gt 0>
						<cfset message.addAll(status) />
					</cfif>
				</cfif>
				<!--- if access was defined, check that --->
				<cfif structkeyexists(fRules,"ACCESS")>
					<cfset status = validateAccess(fRules,aFuncs[i],aFuncs[i]['NAME'],cName) />
					<cfif arraylen(status) gt 0>
						<cfset message.addAll(status) />
					</cfif>
				</cfif>
				<!--- if returntype was defined, check that --->
				<cfif structkeyexists(fRules,"RETURNTYPE")>
					<cfset status = validateReturnType(fRules,aFuncs[i],aFuncs[i]['NAME'],cName) />
					<cfif arraylen(status) gt 0>
						<cfset message.addAll(status) />
					</cfif>
				</cfif>
			</cfif>
		</cfloop>
		<!--- looped over the functions at this level. Do we need to go deeper into an extension chain? --->
		<cfif structkeyexists(arguments.stMetadata.EXTENDS,"EXTENDS") AND structkeyexists(arguments.stMetadata.EXTENDS.EXTENDS,"EXTENDS")>
			<!--- gettin' all recursive and stuff :) --->
			<cfset message.addAll(validateFunctions(arguments.stMetadata.EXTENDS)) />
		</cfif>

		<cfreturn message />
	 </cffunction>
	 
	 <cffunction name="validateArgs" returntype="array" output="false" hint="I perform the work of validating arguments against the relevant rules defined.">
	 	<cfargument name="rules" type="struct" required="true" />
		<cfargument name="params" type="struct" required="true" hint="I am the structure of metadata provided for the function being evaluated" />
		<cfargument name="fName" type="string" required="true" hint="I am the name of the function we're evaluating params for" />
		<cfargument name="cName" type="string" required="true" hint="I am the name of the component the params' parent function came from" />
		<cfset var retval = [] />
		<cfset var a = "" />
		<cfset var args = [] />
		
		<cfif structkeyexists(arguments.params,"PARAMETERS")>
			<cfset args = arguments.params.parameters />
			
			<!--- since our rules are driving things, let's loop over the args defined in our rules --->
			<cfloop collection="#arguments.rules.args#" item="a">
				<!--- first, make sure the target argument exists in our params array --->
				<cfset targParam  = getParam(a,args) />
				<cfif structcount(targParam) gt 0>
					<!--- any other rules we need to validate regarding parameters? --->
					<cfif structkeyexists(arguments.rules.args[a],"REQUIRED")>
						<!--- is this parameter marked as required in the function? --->
						<cfif structkeyexists(targParam,"REQUIRED")>
							<cfif targParam.REQUIRED IS NOT arguments.rules.args[a]['REQUIRED']>
								<cfset arrayAppend(retval,"The REQUIRED attribute of argument #a# in function #arguments.fName# in component #arguments.cName# is annotated as #targParam.REQUIRED# but SHOULD be annotated as #arguments.rules.args[a]['REQUIRED']#") />
							</cfif>
						<cfelse>
							<cfif arguments.rules.args[a]['REQUIRED'] IS NOT "false">
								<cfset arrayAppend(retval,"Argument #a# in function #arguments.fName# in component #arguments.cName# is REQUIRED, but was not annotated as such in the function") />
							</cfif>
						</cfif>
					</cfif>
					<cfif structkeyexists(arguments.rules.args[a],"TYPE")>
						<cfif structkeyexists(targParam,"TYPE")>
							<cfif targParam.TYPE IS NOT arguments.rules.args[a]['TYPE']>
								<cfset arrayAppend(retval,"Argument #a# in function #arguments.fName# in component #arguments.cName# has a type of #targParam.TYPE# but SHOULD be of type #arguments.rules.args[a]['TYPE']#") />
							</cfif>
						<cfelse><!--- this parameter didn't have a type specified.  --->
							<cfset arrayAppend(retval,"Argument #a# in function #arguments.fName# in component #arguments.cName# does not have a type specified. It SHOULD be of type #arguments.rules.args[a]['TYPE']#") />
						</cfif>
					</cfif>
					
				<cfelse>
					<cfset arrayAppend(retval,"Argument #a# in function #arguments.fName# in component #arguments.cName# is required but was not present. ") /> 
				</cfif>
				
			</cfloop>
		</cfif>
		<cfreturn retval />
	 </cffunction>
	
	<cffunction name="getParam" access="private" returntype="struct" output="false" hint="I grab the targeted argument structure that is being validated from the metadata">
		<cfargument name="targParam" type="string" required="true" hint="I am the name of the parameter we're looking for"/>
		<cfargument name="paramArray" type="array" required="true" hint="I am the array of parameters for a specific function in the metadata"/>
		<cfset var retval = {} />
		<cfset var i = 0 />
		
		<cfloop from="1" to="#arrayLen(arguments.paramArray)#" index="i">
			<cfif arguments.paramArray[i]['NAME'] IS arguments.targParam>
				<cfset retval = arguments.paramArray[i] />
				<cfreturn retval />
			</cfif>
		</cfloop>
		
		<cfreturn retval />
	</cffunction>
	
	 <cffunction name="validateAccess" returntype="array" output="false" hint="I validate the access attribute value for a given function">
	 	<cfargument name="rules" type="struct" required="true" hint="I am the relevant rules structure for this call"/>
		<cfargument name="params" type="struct" required="true" hint="I am the structure of metadata provided for the function being evaluated"/>
		<cfargument name="fName" type="string" required="true" hint="I am the name of the function we're evaluating params for" />
		<cfargument name="cName" type="string" required="true" hint="I am the name of the component the params' parent function came from" />

		<cfset var retval = [] />
		
		<cfif structkeyexists(arguments.rules,"ACCESS")>
			<cfif structkeyexists(arguments.params,"ACCESS")>
				<cfif arguments.rules.access IS NOT arguments.params.access>
					<cfset arrayAppend(retval,"Function #arguments.fName# in component #arguments.cName# has an access type of #arguments.params.access# but SHOULD have an access type of #arguments.rules.access# ") />
				</cfif>
			<cfelse>
				<cfset arrayAppend(retval,"Function #arguments.fName# in component #arguments.cName# does not have an ACCESS value specified. It SHOULD be a value of #arguments.rules.access#") />
			</cfif>
		</cfif>
		
		<cfreturn retval />
	 </cffunction>

	 <cffunction name="validateReturnType" returntype="array" output="false" hint="I validate the returntype attribute value for a given function">
	 	<cfargument name="rules" type="struct" required="true" hint="I am the relevant rules structure for this call" />
		<cfargument name="params" type="struct" required="true" hint="I am the structure of metadata provided for the function being evaluated" />
		<cfargument name="fName" type="string" required="true" hint="I am the name of the function we're evaluating params for" />
		<cfargument name="cName" type="string" required="true" hint="I am the name of the component the params' parent function came from" />
		
		<cfset var retval = [] />
		
		<cfif structkeyexists(arguments.rules,"RETURNTYPE")>
			<cfif structkeyexists(arguments.params,"RETURNTYPE")>
				<cfif arguments.rules.returntype IS NOT arguments.params.returntype>
					<cfset arrayAppend(retval,"Function #arguments.fName# in component #arguments.cName# has a RETURNTYPE of #arguments.params.returntype# but SHOULD have a returntype of #arguments.rules.returntype# ") />
				</cfif>
			<cfelse>
				<cfset arrayAppend(retval,"Function #arguments.fName# in component #arguments.cName# does not have a RETURNTYPE specified. It SHOULD be a value of #arguments.rules.returntype#") />
			</cfif>
		</cfif>
		
		<cfreturn retval />
	 </cffunction>	
	  	 
	 <cffunction name="nameMatch" returntype="struct" output="true" access="private" hint="Considering the current function name (argument 'fName'), I loop over my rules array to see if the name matches any of the regex definitions. If I DO find a match, I return the rules structure for THAT regex.">
	 	<cfargument name="fName" type="string" hint="I am the name of the function we're currently looking at" />
		<cfset var retval = {} />
		<cfloop from="1" to="#arraylen(getRules())#" index="i">
			<cfif arraylen(reMatch(getRules()[i]['NAME'],arguments.fName)) gt 0>
				<cfset retval = getRules()[i] />
			</cfif>
		</cfloop>
		<cfreturn retval />
	 </cffunction>
	 
	 <cffunction name="getRules" returntype="array" access="public" 
	 	hint="I return the rules array that the user defined. the rules array can have the following keys within individual structures:
		<ul>
			<li>(required)name = a regex expression that a function name must match in order for the remaining rules in this key to be applied</li>
			<li>
				(optional)args = a structure of individual argument names
				<ul>
					<li>(optional)[argument name] = a structure of attribute rules</li>
					<ul><li>(optional)[attribute] = [the value this attribute should have]</li></ul>
				</ul>
			</li>
			<li>(optional)access = the access value that the matching function must have</li>
			<li>(optional)returntype = the returntype that the matching function must have</li>
		</ul>
		<pre>
		<strong>Sample rules array:</strong>
	 	<cfscript>
	 		stRules = [
				{
					name = '^format(?!Value).+?',//any method like 'formatX', but ignoring 'formatValue'
					args = {
						targetValue = {
							type = 'string',
							required = 'true'
						}
					},
					access = 'private',
					returntype = 'string'
				},
				{
					name = '^validate(?!Value).+?',//any method like 'validateX', but ignoring 'validateValue'
					args = {
						targetValue = {
							type = 'string',
							required = 'true'
						}
					},
					access = 'private',
					returntype = 'boolean'
				}
			];
			return stRules;
		</cfscript>
		</pre>
		"
	>
	 	<!--- 
	 		the rules array can have the following keys within individual structures:
			 (required)name = a regex expression that a function name must match in order for the remaining rules in this key to be applied
			 (optional)args = a structure of individual argument names
			 	(optional)[argument name] = a structure of attribute rules
					(optional)[attribute] = [the value this attribute should have]
					
			 (optional)access = the access value that the matching function must have
			 (optional)returntype = the returntype that the matching function must have
		 --->
	 	<cfscript>
	 		stRules = [
				{
					name = "^format(?!Value).+?",//any method like 'formatX', but ignoring 'formatValue'
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
					name = "^validate(?!Value).+?",//any method like 'validateX', but ignoring 'validateValue'
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
	 </cffunction>
</cfcomponent>