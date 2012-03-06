<cfcomponent displayname="Logger" hint="Logs errors to a text file" output="false">

	<cffunction name="init" displayname="Initializer" hint="" output="false" 
		access="public" returntype="Logger">		
		<cfreturn this />
	</cffunction>

	<cffunction name="logError" displayname="Log Error" hint="Logs error details to specified file" output="false" 
		access="public" returntype="boolean">
		<cfargument name="log_file" type="string" hint="Full path to the log file" required="true">		
		<cfargument name="error_detail" type="string" hint="Error details string" required="true" />
		
		<cfscript>
			var logged = false;
			var err = "Error Details: " & arguments.error_detail;
		</cfscript>
		
		<cftry>
			<cffile action="append" file="#arguments.log_file#" output="#err#">
			<cfset logged = true />
			<cfcatch type="any"></cfcatch>
		</cftry>
		
		<cfreturn logged />
	</cffunction>
	
	<cffunction name="logAndEmail" displayname="Log and Email" hint="Logs an error and emails the log file" output="false" 
		access="public" returntype="boolean">
		<cfargument name="log_file" type="string" hint="Full path to the log file" required="true">
		<cfargument name="email_address" type="string" hint="Email to which we send the log file" required="true" />
		
		<cfscript>
			var logged_and_emailed = false;
			var email_verification = createObject( 'component', 'EmailVerifier' ).verifyEmail( Trim( arguments.email_address ) );
			var valid_log_file = FileExists( Trim( arguments.log_file ) );
			var logged = logError( Trim(arguments.log_file ) );
		</cfscript>
		
		<cfif email_verification.verified and valid_log_file>
			<cfmail to="#Trim(arguments.email_address)#" from="#Trim(arguments.email_address)#" subject="Zipper Utility Error Log" type="html">
				<cfmailparam type="plain" file="#arguments.log_file#">
				<p>The Zipper Utility log file has been updated and attached.</p>
			</cfmail>
			<cfset logged_and_emailed = true />
		</cfif>
		
		<cfreturn logged_and_emailed />
	</cffunction>
	
	<cffunction name="clearLog" displayname="Clear Log" hint="Clears log file" output="false" 
		access="public" returntype="boolean">
		<cfargument name="log_file" type="string" hint="Full path to the log file" required="true">
		
		<cfscript>
			var cleared = false;
			var valid_log_file = FileExists( Trim( arguments.log_file ) );
		</cfscript>
		
		<cfif valid_log_file>
			<cftry>
				<cffile action="delete" file="#Trim(arguments.log_file)#" />
				<cffile action="write" file="#Trim(arguments.log_file)#" output="" />
				<cfset cleared = true />
				<cfcatch type="any"></cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn cleared />
	</cffunction>

</cfcomponent>