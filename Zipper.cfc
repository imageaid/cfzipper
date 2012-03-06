<cfcomponent displayname="Zipper" hint="Zips a collection of files into a single archive" output="false" extends="ZipperBean">
	
	<!--- INIT --->
	<cffunction name="init" displayname="Initializer" access="public" output="false" returntype="Zipper">
		<cfscript>
			super.init();
		</cfscript>
		<cfreturn this />
	</cffunction>
	
	<!--- METHODS --->
	<cffunction name="zip" displayname="Zip" hint="Zips the specified files/directories" output="false" 
			access="remote" returntype="string">	
		<cfargument name="files" type="array" required="true" />
			
		<cfscript>
			var file = "";
			var result = "failure";
			var path = "";
			var project = "";
			setFiles_to_zip( arguments.files );
		</cfscript>
		
		<cfif ArrayLen( files )>
			<cftry>
				<cfzip action="zip" file="#getSave_location()##getZip_archive()#" overwrite="true">
					<cfloop from="1" to="#ArrayLen( files )#" index="i">
						<!--- 
						## if it's a file, add it to the zip
						 --->
						<cfif FileExists( files[i] )>
							<cfzipparam source="#files[i]#" />	
						<!--- 
						## if it's a directory and if recursive is true, zip 'em up
						 --->
						<cfelseif DirectoryExists( files[i] ) and getRecursive()>
							<cfdirectory action="list" directory="#files[i]#" name="directory">
							<cfscript>
								path = GetDirectoryFromPath( directory.directory & getSlash() & "index.cfm" );
								project = getLastDirectoryInPath( path );
							</cfscript>
							<cfzipparam source="#files[i]#" prefix="#project#" />				
						<!--- 
						## if it's a directory and recursive is false, 
						## get all the files for this dir only (no sudirectories)
						## and add them to the zip archive
						 --->
						<cfelseif DirectoryExists( files[i] ) and not getRecursive()>
							<cfdirectory action="list" directory="#files[i]#" name="fileDir" type="file" />
							<cfscript>
								path = GetDirectoryFromPath( fileDir.directory & getSlash() & "index.cfm" );
								project = getLastDirectoryInPath( path );
							</cfscript>
							<cfif fileDir.RecordCount>
								<cfloop query="fileDir">
									<cfset file = path & fileDir.name />
									<cfif FileExists( file ) and Ucase( fileDir.attributes ) neq 'H'>
										<cfzipparam source="#file#" prefix="#project#" />	
									</cfif>
								</cfloop>
							</cfif>
						</cfif>
					</cfloop>
				</cfzip>
				<cfset zipped = true />
				<cfcatch type="any">
					<cfscript>
						this.logger.logError( getLog_file(), cfcatch.message );
					</cfscript>
				</cfcatch>
			</cftry>				
		</cfif>
		
		<!--- run the execute method and clean up after ourselves --->
		<cfscript>
			result = execute();
		</cfscript>
		<cfreturn result />		
	</cffunction>
	
	<cffunction name="execute" displayname="Execute" hint="Runs the zip action" output="false" 
		access="package" returntype="string">
		<!--- based on the delivery_mechanism, deliver the file --->
		<cfswitch expression="#getDelivery_mechanism()#">
			<cfcase value="browser">
				<cfset result = sendArchiveToBrowser() />
			</cfcase>
			<cfcase value="email">
				<cfset result = sendArchiveByEmail() />
			</cfcase>
			<cfcase value="disk">
				<cfset result = saveArchiveToDisk() />
			</cfcase>
			<cfdefaultcase>
				<cfset result = sendArchiveToBrowser() />
			</cfdefaultcase>
		</cfswitch>
		
		<cfreturn result />
	</cffunction>
	
	<cffunction name="sendArchiveByEmail" displayname="Send Archive by Email" hint="Sends the zip archive via email" output="false" 
			access="remote" returntype="string">
		
		<cfscript>
			var email_sent = "failure";
			var email_verifier = createObject( 'component', 'EmailVerifier' ).init();
			var email_verified = false;
			// ensure that (a) we have an file_recipient value set and (b) it's a valid email
			email_verified = email_verifier.verifyEmail( email_content.recipient );
		</cfscript>
		
		<!--- email_props.verified will be true if the email is good --->
		<cfif email_props.verified>
			<cftry>
				<cfmail to="#getEmail_recipient()#" from="#getEmail_sentby()#" subject="#getEmail_subject()#" type="html">
					<cfmailparam file="#getSave_location()##getZip_archive()#" disposition="attachment" type="" />
						#getEmail_message()#
				</cfmail>
				<cfset email_sent = "email" />
				<cfcatch type="any">
					<!--- log error --->
					<cfscript>
						this.logger.logError( getLog_file(), cfcatch.message );
					</cfscript>
				</cfcatch>
			</cftry>
		</cfif>			
		
		<cfset cleanUp() />
		
		<cfreturn email_sent />		
	</cffunction>
	
	<cffunction name="sendArchiveToBrowser" displayname="sendArchiveToBrowser" hint="Sends the archive to the users browser for download" output="true" 
			access="remote" returntype="string">			
		<cfscript>
			var zip_archive_name = GetFileFromPath( getSave_location() & getZip_archive() );
			var archive_sent = "failure";
			var err = "";
		</cfscript>
		
		<cfthread action="run" name="waittodelete" timeout="250">
			<cfscript>
				cleanUp();
			</cfscript>
		</cfthread>
		
		<cftry>
			<cfheader name="Content-Disposition" value="attachment; filename=#zip_archive_name#"> 
			<cfcontent type="application/octet-stream" file="#getSave_location()##getZip_archive()#">
			<cfset archive_sent = "browser" />
			<cfcatch type="any">
				<!--- log error --->
				<cfscript>
					this.logger.logError( getLog_file(), cfcatch.message );
				</cfscript>
			</cfcatch>
		</cftry>
		
		<cfreturn archive_sent />		
	</cffunction>
	
	<cffunction name="saveArchiveToDisk" displayname="Save Archive Disk" hint="Saves the archive to the file system" output="false" 
			access="remote" returntype="string">
		<cfscript>
			var saved_zip = "failure";
			var archive_name = GetFileFromPath( getSave_location() & getZip_archive() );
			var save_to = Trim( getSave_location() );
		</cfscript>
		
		<cfif save_to is not "">
			<cftry>
				<cffile action="move" source="#getSave_location()##getZip_archive()#" destination="#save_to##archive_name#" />
				<cfset saved_zip = getSave_url() & archive_name />
				<cfcatch type="any">
					<!--- log error --->
					<cfscript>
						this.logger.logError( getLog_file(), cfcatch.message );
					</cfscript>
				</cfcatch>
			</cftry>
		</cfif>
		
		<cfreturn saved_zip />		
	</cffunction>

	<cffunction name="cleanUp" displayname="Clean Up" hint="Removes the created archive from the system" output="false" 
		access="package" returntype="void">
		<!--- remove the originally created zip archive from the server --->
		<cfif FileExists( getSave_location() & getZip_archive() )>
			<cftry>
				<cffile action="delete" file="#getSave_location()##getZip_archive()#" />
				<cfcatch type="any">
					<!--- log error --->
					<cfscript>
						this.logger.logError( getLog_file(), cfcatch.message );
					</cfscript>
				</cfcatch>	
			</cftry>			
		<cfelse>
			<cfscript>
				this.logger.logError( getLog_file(), "No file to delete during cleanUp method execution." );
			</cfscript>
		</cfif>
		
		<cfreturn />
	</cffunction>
	
	<cffunction name="getLastSlashPosition" displayname="Get Last Slash Position in Path" hint="Returns the position, integer, of the last slash in a path" 
		output="false" access="private" returntype="numeric">
		<cfargument name="path" type="string" required="true" />
		
		<cfscript> 
			var position = ReFind( "([^\\\/]+[\\\/]){1}$", arguments.path, 0 ) - 1;
		</cfscript>
		
		<cfreturn position />
	</cffunction>
	
	<cffunction name="getLastDirectoryInPath" displayname="Get Last Directory in Path" hint="" output="false" 
		access="package" returntype="string">
		<cfargument name="path" type="string" required="true" />
		
		<cfscript>
			var full_path = Trim( arguments.path );
			var directory = "";
			var last_folder_start = getLastSlashPosition( full_path );
			var directory_raw = RemoveChars( full_path, 1, last_folder_start );
			directory = ReReplace( directory_raw, '/', '', 'ALL');
		</cfscript>
		
		<cfreturn directory />
	</cffunction>

</cfcomponent>