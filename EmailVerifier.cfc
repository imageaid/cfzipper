<cfcomponent displayname="Email Verifier" hint="Validates and Verifies Existence of Email Addres">

	<cffunction name="init" displayname="Initializer" access="public" output="false" returntype="EmailVerifier">
		<cfreturn this />
	</cffunction>
	
	<!--- 
		* Verifies the existence of an email address by checking the provided email address against the ValidateEmail web service.
		* 
		* @param emailaddress  string containing the email address to test
		* @return struct ( verified: true/false; message: String; resultCode:String; wsdl:String; attemptTime:Date  )
		* @author Craig Kaminsky (imageaid@gmail.com) 
		* @version 1, May 6, 2009
	 --->		 
	<cffunction name="verifyEmail" displayname="Verify Email Existence" access="remote" output="false" returntype="struct">
		<cfargument name="emailaddress" displayname="Email Address" type="string" required="true" />
		<cfscript>
			var email_address = Trim( arguments.emailaddress );
			var results = StructNew();
			var validationResponse = "";
			var ws = "";
			// add the default keys and values for returned struct 
			results.wsdl = "http://www.webservicex.net/ValidateEmail.asmx?wsdl";
			results.attemptTime = Now();
			// setup the web service
			ws = createObject( "webservice", results.wsdl );
		</cfscript>
		
		<cfscript>
			if( IsValid( "email", email_address ))
			{
				// setup some exception handling just in case the Web Service is down, etc.
				try
				{
					validationResponse = ws.IsValidEmail( Email=email_address );
				}
				catch( Any err )
				{
					results.verified = false;
					results.message = "Web Service response error: " + err.Message;
					results.resultCode = "fail";
					// exit the function and return the results struct
					return results;
				}			
				// check the response from the web service
				if( Trim( validationResponse ) is "YES" )
				{
					results.verified = true;
					results.message = "Email address passed validation and verification.";
					results.resultCode = "valid";
				}
				else
				{
					results.verified = false;
					results.message = "Email address passed validation but failed verification.";
					results.resultCode = "invalid";
				}
			}
			else
			{
				results.verified = false;
				results.message = "Email address failed validation. It is not properly formatted.";
				results.resultCode = "invalid";
			}
		</cfscript>
		
		<cfreturn results />
	</cffunction>
	
	<!--- 
		* An Ajax-wrapper for the verifyEmail function
		* 
		* @param emailaddress  string containing the email address to test
		* @return void (outputs JSON data to the browser for the calling JavaScript to read)
		* @author Craig Kaminsky (imageaid@gmail.com) 
		* @version 1, May 8, 2009
	 --->	
	<cffunction name="ajaxVerifyEmail" displayname="Ajax-enabled Email Verification" access="remote" output="true">
		<cfargument name="email_address" type="string" required="true" />
		
		<cfscript>
			var results = verifyEmail( Trim(email_address) );
			var output = SerializeJSON( results );
		</cfscript>
		
		<cfoutput>#output#</cfoutput>
		
	</cffunction>

</cfcomponent>