using System.Data.Services;
using System.Data.Services.Common;
using System.ServiceModel.Web;
using System.Web;
using Model;

public class Entities : DataService< ModelContainer >
{
    // This method is called only once to initialize service-wide policies.
    public static void InitializeService(DataServiceConfiguration config)
    {
        config.SetEntitySetAccessRule("*", EntitySetRights.All);
        config.SetServiceOperationAccessRule("*", ServiceOperationRights.All);
        config.DataServiceBehavior.MaxProtocolVersion = DataServiceProtocolVersion.V2;
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

    protected override void OnStartProcessingRequest(ProcessRequestArgs args)
    {
        base.OnStartProcessingRequest(args);
        if (args.RequestUri.AbsoluteUri.ToLower().EndsWith("cleandatabasefortesting"))
        {
            if (HttpContext.Current.Request.UserHostAddress != "127.0.0.1")
                throw new DataServiceException(401, "Access Denied");
        }
    }
}
