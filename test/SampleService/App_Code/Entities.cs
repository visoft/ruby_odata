using System.Data.Services;
using System.Data.Services.Common;
using System.ServiceModel;
using System.ServiceModel.Web;
using System.Web;
using System;
using System.Linq;   
using System.Security.Principal;
using System.Text;
using Model;

[ServiceBehavior(IncludeExceptionDetailInFaults = true)]
public class Entities : DataService< ModelContainer >
{
    // This method is called only once to initialize service-wide policies.
    public static void InitializeService(DataServiceConfiguration config)
    {
        config.SetEntitySetAccessRule("*", EntitySetRights.All);
        config.SetServiceOperationAccessRule("*", ServiceOperationRights.All);
        config.DataServiceBehavior.MaxProtocolVersion = DataServiceProtocolVersion.V2;
        config.UseVerboseErrors = true;
    }

    /// <summary>
    /// Cleans the database for testing.
    /// </summary>
    [WebInvoke]
    public void CleanDatabaseForTesting()
    {
        var context = new ModelContainer();
        context.ExecuteStoreCommand("ALTER TABLE [dbo].[Products] DROP CONSTRAINT [FK_CategoryProduct]");
        context.ExecuteStoreCommand("TRUNCATE TABLE [dbo].[Categories]; TRUNCATE TABLE [dbo].[Products]");
        context.ExecuteStoreCommand("ALTER TABLE [dbo].[Products] ADD CONSTRAINT [FK_CategoryProduct] FOREIGN KEY ([Category_Id]) REFERENCES [dbo].[Categories]([Id])");

    }
}
 
public class OurBasicAuthenticationModule: IHttpModule 
{ 
    public void Init(HttpApplication context) 
    { 
        context.AuthenticateRequest 
           += new EventHandler(context_AuthenticateRequest); 
    }
     
    void context_AuthenticateRequest(object sender, EventArgs e) 
    { 
        HttpApplication application = (HttpApplication)sender; 

        // Only require authentication if BasicAuth is in the URI path
        if (( application.Context.Request.Url.AbsoluteUri.Contains("BasicAuth")) &&
            (!CustomBasicAuthenticationProvider.Authenticate(application.Context))) 
        { 
            application.Context.Response.Status = "401 Unauthorized"; 
            application.Context.Response.StatusCode = 401; 
            application.Context.Response.AddHeader("WWW-Authenticate", "Basic"); 
            application.CompleteRequest(); 
        } 
    }

    public void Dispose() { }

}    // class OurBasicAuthenticationModule: IHttpModule 

public class CustomBasicAuthenticationProvider
{
    public static bool Authenticate(HttpContext context) 
    {      
        if (!HttpContext.Current.Request.Headers.AllKeys.Contains("Authorization")) 
            return false;
    
        string authHeader = HttpContext.Current.Request.Headers["Authorization"];
    
        IPrincipal principal; 
        if (TryGetPrincipal(authHeader, out principal)) 
        { 
            HttpContext.Current.User = principal; 
            return true; 
        } 
        return false; 
    } 

    private static bool TryGetPrincipal(string authHeader, out IPrincipal principal) 
    { 
        var creds = ParseAuthHeader(authHeader); 
        if (creds != null && TryGetPrincipal(creds, out principal)) 
            return true;
    
        principal = null; 
        return false; 
    }

    private static bool TryGetPrincipal(string[] creds,out IPrincipal principal) 
    { 
        if (creds[0] == "admin" && creds[1] == "passwd") 
        { 
            principal = new GenericPrincipal( 
               new GenericIdentity("Administrator"), 
               new string[] {"Administrator", "User"} 
            ); 
            return true; 
        }         
        else 
        { 
            principal = null; 
            return false; 
        } 
    }

    private static string[] ParseAuthHeader(string authHeader) 
    { 
        // Check this is a Basic Auth header 
        if ( 
            authHeader == null || 
            authHeader.Length == 0 || 
            !authHeader.StartsWith("Basic") 
        ) return null;
    
        // Pull out the Credentials with are seperated by ':' and Base64 encoded 
        // Won't handle password with : in it, but that's OK for these tests
        string base64Credentials = authHeader.Substring(6); 
        string[] credentials = Encoding.ASCII.GetString( 
              Convert.FromBase64String(base64Credentials) 
        ).Split(new char[] { ':' }); 
    
        if (credentials.Length != 2 || 
            string.IsNullOrEmpty(credentials[0]) || 
            string.IsNullOrEmpty(credentials[0]) 
        ) return null;
            
        return credentials; 
    }    

}    // class CustomBasicAuthenticationProvider
