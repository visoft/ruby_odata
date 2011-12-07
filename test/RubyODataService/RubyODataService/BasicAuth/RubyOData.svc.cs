using System;
using System.Linq;
using System.Security.Principal;
using System.Text;
using System.Web;

// ReSharper disable CheckNamespace
namespace RubyODataService
// ReSharper restore CheckNamespace
{
    public class OurBasicAuthenticationModule : IHttpModule
    {
        public void Init(HttpApplication context)
        {
            context.AuthenticateRequest += context_AuthenticateRequest;
        }

        private void context_AuthenticateRequest(object sender, EventArgs e)
        {
            HttpApplication application = (HttpApplication)sender;

            // Only require authentication if BasicAuth is in the URI path
            if ((application.Context.Request.Url.AbsoluteUri.Contains("BasicAuth")) &&
                (!CustomBasicAuthenticationProvider.Authenticate(application.Context)))
            {
                application.Context.Response.Status = "401 Unauthorized";
                application.Context.Response.StatusCode = 401;
                application.Context.Response.AddHeader("WWW-Authenticate", "Basic");
                application.CompleteRequest();
            }
        }

        public void Dispose()
        {
        }

    }

    // class OurBasicAuthenticationModule: IHttpModule 

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

        private static bool TryGetPrincipal(string[] creds, out IPrincipal principal)
        {
            if (creds[0] == "admin" && creds[1] == "passwd")
            {
                principal = new GenericPrincipal(
                    new GenericIdentity("Administrator"),
                    new[] { "Administrator", "User" }
                    );
                return true;
            }
            principal = null;
            return false;
        }

        private static string[] ParseAuthHeader(string authHeader)
        {
            // Check this is a Basic Auth header 
            if (
                string.IsNullOrEmpty(authHeader) ||
                !authHeader.StartsWith("Basic")
                ) return null;

            // Pull out the Credentials with are seperated by ':' and Base64 encoded 
            // Won't handle password with : in it, but that's OK for these tests
            var base64Credentials = authHeader.Substring(6);
            var credentials = Encoding.ASCII.GetString(Convert.FromBase64String(base64Credentials)).Split(new[] { ':' });

            if (credentials.Length != 2 ||
                string.IsNullOrEmpty(credentials[0]) ||
                string.IsNullOrEmpty(credentials[0])
                ) return null;

            return credentials;
        }

    }

    // class CustomBasicAuthenticationProvider
}
