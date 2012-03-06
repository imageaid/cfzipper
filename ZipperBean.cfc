<cfcomponent displayname="Zipper Bean" hint="Base properties of Zipper Object" output="false">

	<!--- PROPERTIES --->
	<cfproperty name="files_to_zip" displayname="Files to Zip" hint="An array of files to include in the archive" type="array" />
	<cfproperty name="zip_archive" displayname="Zip Archive" hint="Full path to the resulting archive" type="string" />
	<cfproperty name="delivery_mechanism" displayname="Delivery Mechanism" hint="The archive delivery method: email, disk, browser" type="string" default="brower" />
	<cfproperty name="save_location" displayname="Save Location" hint="Location at which to save the archive" type="string" default="" />
	<cfproperty name="slash" displayname="Slash" hint="OS-specific slash" type="string" default="/" />
	<cfproperty name="log_file" displayname="Log file" hint="Full path to log file" type="string" default="" />
	<cfproperty name="save_url" displayname="Save URL" hint="URL for saved archives" type="string" default="" />
	<cfproperty name="recursive" displayname="Recursive" hint="Boolean to search subdirectories" type="boolean" default="true" />
	<cfproperty name="email_sentby" displayname="Email Sender" hint="" type="string" default="" />
	<cfproperty name="email_subject" displayname="Email Subject" hint="" type="string" default="" />
	<cfproperty name="email_message" displayname="Email Message" hint="" type="string" default="" />
	<cfproperty name="email_recipient" displayname="Email Recipient" hint="" type="string" default="" />
	
	<cfproperty name="logger" displayname="Logger" hint="Logging Utility" type="Logger" default="" />
	
	<cfscript>
		// private properties
		variables.files_to_zip = ArrayNew(1);
		variables.zip_archive = "";
		variables.delivery_mechanism = "disk";
		variables.save_location = "";
		variables.slash = "\";
		variables.log_file = "";
		variables.save_url = "/archvies/";
		variables.recursive = true;
		variables.email_sentby = "address@email.com";
		variables.email_subject = "Requested Files";
		variables.email_message = "The files you requested are attached in the .zip format.";
		variables.email_recipient = "address@email.com";
		
		// public property (not accessed via getters and setters)
		this.logger = "";
	</cfscript>
	
	<!--- INITIALIZER --->
	<cffunction name="init" displayname="Initializer" access="public" output="false" returntype="ZipperBean">
		<cfscript>
			// setup defaults
			setSlash();
			setZip_archive( CreateUUID() & ".zip" );
			setSave_location( ExpandPath( '.' ) & getSlash() );
			setLog_file( ExpandPath( '.' ) & getSlash() & "zipper.log" );
			this.logger = createObject( 'component', 'Logger' ).init();
		</cfscript>
		<cfreturn this />
	</cffunction>

	<!--- GETTERS AND SETTERS --->		
	<cffunction name="getFiles_to_zip" access="public" output="false" returntype="array">
		<cfreturn variables.files_to_zip />
	</cffunction>

	<cffunction name="setFiles_to_zip" access="public" output="false" returntype="void">
		<cfargument name="files_to_zip" type="array" required="true" />
		<cfset variables.files_to_zip = arguments.files_to_zip />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getZip_archive" access="public" output="false" returntype="string">
		<cfreturn variables.zip_archive />
	</cffunction>

	<cffunction name="setZip_archive" access="public" output="false" returntype="void">
		<cfargument name="zip_archive" type="string" required="true" />
		<cfset variables.zip_archive = Trim( arguments.zip_archive ) />
		<cfreturn />
	</cffunction>

	<cffunction name="getDelivery_mechanism" access="public" output="false" returntype="string">
		<cfreturn variables.delivery_mechanism />
	</cffunction>

	<cffunction name="setDelivery_mechanism" access="public" output="false" returntype="void">
		<cfargument name="delivery_mechanism" type="string" required="true" />
		<cfset variables.delivery_mechanism = Trim( arguments.delivery_mechanism ) />
		<cfreturn />
	</cffunction>

	<cffunction name="getSave_location" access="public" output="false" returntype="string">
		<cfreturn variables.save_location />
	</cffunction>

	<cffunction name="setSave_location" access="public" output="false" returntype="void">
		<cfargument name="save_location" type="string" required="true" />
		<cfset variables.save_location = Trim( arguments.save_location ) />
		<cfreturn />
	</cffunction>

	<cffunction name="getFile_recipient" access="public" output="false" returntype="string">
		<cfreturn variables.file_recipient />
	</cffunction>
	
	<cffunction name="setFile_recipient" access="public" output="false" returntype="void">
		<cfargument name="file_recipient" type="string" required="true" />
		<cfset variables.file_recipient = Trim( arguments.file_recipient ) />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getSlash" access="public" output="false" returntype="string">		
		<cfreturn variables.slash />
	</cffunction>
	
	<cffunction name="setSlash" access="public" output="false" returntype="void">
		<cfargument name="slash" type="string" required="false" default="" />
		<cfif Trim( arguments.slash ) is "">
			<cfset variables.slash = IIf( server.os.name contains 'Windows', De("\"), De("/") ) />
		<cfelse>
			<cfset variables.slash = arguments.slash />
		</cfif>
		<cfreturn />
	</cffunction>
	
	<cffunction name="getLog_file" access="public" output="false" returntype="string">
		<cfreturn variables.log_file />
	</cffunction>
	
	<cffunction name="setLog_file" access="public" output="false" returntype="void">
		<cfargument name="log_file" type="string" required="true" />
		<cfset variables.log_file = arguments.log_file />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getSave_url" access="public" output="false" returntype="string">
		<cfreturn variables.save_url />
	</cffunction>
	
	<cffunction name="setSave_url" access="public" output="false" returntype="void">
		<cfargument name="save_url" type="string" required="true" />
		<cfset variables.save_url = arguments.save_url />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getRecursive" access="public" output="false" returntype="boolean">
		<cfreturn variables.recursive />
	</cffunction>
	
	<cffunction name="setRecursive" access="public" output="false" returntype="void">
		<cfargument name="recursive" type="boolean" required="true" />
		<cfset variables.recursive = arguments.recursive />
		<cfreturn />
	</cffunction>

	<cffunction name="getEmail_sentby" access="public" output="false" returntype="string">
		<cfreturn variables.email_sentby />
	</cffunction>
	
	<cffunction name="setEmail_sentby" access="public" output="false" returntype="void">
		<cfargument name="email_sentby" type="string" required="true" />
		<cfset variables.email_sentby = arguments.email_sentby />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getEmail_subject" access="public" output="false" returntype="string">
		<cfreturn variables.email_subject />
	</cffunction>
	
	<cffunction name="setEmail_subject" access="public" output="false" returntype="void">
		<cfargument name="email_subject" type="string" required="true" />
		<cfset variables.email_subject = arguments.email_subject />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getEmail_message" access="public" output="false" returntype="string">
		<cfreturn variables.email_message />
	</cffunction>
	
	<cffunction name="setEmail_message" access="public" output="false" returntype="void">
		<cfargument name="email_message" type="string" required="true" />
		<cfset variables.email_message = arguments.email_message />
		<cfreturn />
	</cffunction>
	
	<cffunction name="getEmail_recipient" access="public" output="false" returntype="string">
		<cfreturn variables.email_recipient />
	</cffunction>
	
	<cffunction name="setEmail_recipient" access="public" output="false" returntype="void">
		<cfargument name="email_recipient" type="string" required="true" />
		<cfset variables.email_recipient = arguments.email_recipient />
		<cfreturn />
	</cffunction>

</cfcomponent>